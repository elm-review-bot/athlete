module Elegant.Convert exposing (..)

import Helpers.Css
import List.Extra
import Maybe.Extra exposing ((?))
import Dict exposing (Dict)
import Helpers.Style exposing (..)
import Display


compileStyle : Display.DisplayBox -> List ( String, String )
compileStyle displayBox =
    Display.displayBoxToCouples displayBox



{- This parts focused on generating classes names from Style and ScreenWidths.
   classesNamesFromStyle accepts the content of a Style object, and
   generates a list of Strings containing all classes names relative to the Style object.
   The function can take a suffix, which is a Maybe String. This symbolize the
   possible suffix of the style, i.e. the pseudo-classes and selectors in CSS.

   classesNamesFromStyle (Just "hover") generates classes names
   looking like my-example-class-name_hover, where classesNamesFromStyle
   Nothing generates classes names looking like my-example-class-name. This is useful
   to later generates the corresponding CSS class my-example-class-name_hover:hover
   containing styles, visible only on hover. This allows to handle all possible
   pseudo-classes and selectors, while keeping CSS classes as short as possible.
-}


classesNamesFromStyle : Style -> List String
classesNamesFromStyle ({ screenWidths, display, suffix } as style) =
    let
        standardClassesNames =
            display
                |> Maybe.map compileStyle
                |> Maybe.withDefault []
                |> classesNameGeneration suffix
    in
        screenWidths
            |> List.concatMap (screenWidthToClassesNames suffix)
            |> List.append standardClassesNames


classesNameGeneration : Maybe String -> List ( String, String ) -> List String
classesNameGeneration suffix =
    List.map (Helpers.Css.generateClassName suffix)


screenWidthToClassesNames : Maybe String -> ScreenWidth -> List String
screenWidthToClassesNames suffix { min, max, style } =
    style
        |> compileStyle
        |> classesNameGeneration suffix
        |> List.map (addScreenWidthToClassName min max)


addScreenWidthToClassName : Maybe Int -> Maybe Int -> String -> String
addScreenWidthToClassName min max className =
    (toString min ++ toString max)
        |> Helpers.Css.cssValidName
        |> (++) className



{- This part focus on generating CSS classes from Style. The main function is
   stylesToCss, accepting a list of Style, and generating the list of corresponding
   CSS classes. The first step consists to extract all the styles from the various
   screen widths (i.e. media queries in CSS), and merging them with the default styles.
   Then, they are transformed to atomic classes. They are records with the strict
   minimum inside, to turn them in CSS classes easily. Pre-compiled code are then added
   before returning the result.

   Using the same classes names generator than before, the classes matches easily
   and gives the correct behavior. The main function (fetchStylesOrCompute) is a
   caching function. The first thing done is to fetch if the Style has already
   been compiled. If it is, it just extract the styles from the cache, and returns
   them. Otherwise, it compiles the styles, and inserts them into the cache, for
   later use.
-}


stylesToCss : List Style -> List String
stylesToCss styles =
    styles
        |> List.foldr fetchStylesOrCompute ( Dict.empty, [] )
        |> Tuple.second
        |> List.append [ boxSizingCss ]
        |> List.Extra.unique


fetchStylesOrCompute : Style -> ( Dict String (List String), List String ) -> ( Dict String (List String), List String )
fetchStylesOrCompute style ( cache, accumulator ) =
    let
        styleHash =
            style |> toString
    in
        case Dict.get styleHash cache of
            Nothing ->
                let
                    computedStyles =
                        style
                            |> extractScreenWidths
                            |> List.concatMap compileConditionalStyle
                            |> List.map compileAtomicClass
                in
                    ( Dict.insert styleHash computedStyles cache, List.append computedStyles accumulator )

            Just computedStyles ->
                ( cache, List.append computedStyles accumulator )


type alias ConditionalStyle =
    { display : Display.DisplayBox
    , suffix : Maybe String
    , mediaQuery : Maybe ( Maybe Int, Maybe Int )
    }


extractScreenWidths : Style -> List ConditionalStyle
extractScreenWidths ({ display, suffix, screenWidths } as style) =
    screenWidths
        |> List.map (extractScreenWidth suffix)
        |> addDefaultStyle style


extractScreenWidth : Maybe String -> ScreenWidth -> ConditionalStyle
extractScreenWidth suffix { style, min, max } =
    { display = style
    , suffix = suffix
    , mediaQuery = Just ( min, max )
    }


addDefaultStyle : Style -> List ConditionalStyle -> List ConditionalStyle
addDefaultStyle { display, suffix, screenWidths } styles =
    case display of
        Nothing ->
            styles

        Just display_ ->
            { display = display_
            , suffix = suffix
            , mediaQuery = Nothing
            }
                :: styles


type alias AtomicClass =
    { mediaQuery : Maybe String
    , className : String
    , mediaQueryId : Maybe String
    , selector : Maybe String
    , property : String
    }


compileConditionalStyle : ConditionalStyle -> List AtomicClass
compileConditionalStyle { display, suffix, mediaQuery } =
    display
        |> compileStyle
        |> List.map (coupleToAtomicClass suffix mediaQuery)


coupleToAtomicClass : Maybe String -> Maybe ( Maybe Int, Maybe Int ) -> ( String, String ) -> AtomicClass
coupleToAtomicClass suffix mediaQuery property =
    { mediaQuery = Maybe.map Helpers.Css.generateMediaQuery mediaQuery
    , className = Helpers.Css.generateClassName suffix property
    , mediaQueryId = Maybe.map Helpers.Css.generateMediaQueryId mediaQuery
    , selector = Helpers.Css.generateSelector suffix
    , property = Helpers.Css.generateProperty property
    }


compileAtomicClass : AtomicClass -> String
compileAtomicClass { mediaQuery, className, mediaQueryId, selector, property } =
    inMediaQuery mediaQuery <|
        compileStyleToCss className mediaQueryId selector property


inMediaQuery : Maybe String -> String -> String
inMediaQuery mediaQuery content =
    mediaQuery
        |> Maybe.map (flip (++) (Helpers.Css.surroundWithBraces content))
        |> Maybe.withDefault content


compileStyleToCss : String -> Maybe String -> Maybe String -> String -> String
compileStyleToCss className mediaQueryId selector property =
    String.join ""
        [ "."
        , className
        , (mediaQueryId ? "")
        , (selector ? "")
        , Helpers.Css.surroundWithBraces property
        ]


boxSizingCss : String
boxSizingCss =
    "*{box-sizing: border-box;}"
