module Main exposing (..)

import Html exposing (Html)
import Html.Attributes
import Elegant exposing (px)
import Box
import Typography
import Typography.Character
import BoxShadow
import Border
import Color exposing (Color)
import Corner
import Margin
import Padding
import Cursor
import Outline
import Background
import Position
import Display
import Display.Overflow

main : Html msg
main =
    Html.div
        [ toStyle <| mainStyle ]
        [ Html.text "Just a text." ]


mainStyle : Display.DisplayBox
mainStyle =
    Display.block
        [ Display.overflow
            [ Display.Overflow.overflowX Display.Overflow.hidden
            , Display.Overflow.overflowY Display.Overflow.visible
            ]
        , Display.dimensions
            [ Display.width (px 30)
            , Display.height (px 40)
            ]
        , Display.textOverflowEllipsis
        , Display.alignment Display.left
        , Display.listStyleCircle
        ]
        [ Box.typography
            [ Elegant.color Color.blue
            , Typography.character
                [ Typography.Character.weight 900
                , Typography.Character.size (px 100)
                , Typography.Character.italic
                ]
            ]
        , Box.padding
            [ Padding.all (px 30) ]
        , Box.boxShadow
            [ BoxShadow.standard (px 30) Color.black ( px 3, px 3 )
            , BoxShadow.inset True
            ]
        , Box.border
            [ Border.all
                [ Elegant.color Color.blue
                , Border.solid
                , Border.thickness (px 200)
                ]
            , Border.horizontal
                [ Elegant.color Color.black ]
            , Border.right
                [ Elegant.color Color.lightOrange ]
            ]
        , Box.corner
            [ Corner.circular Corner.all (px 200) ]
        , Box.margin
            [ Margin.top <| Margin.width (px 40)
            , Margin.vertical <| Margin.width (px 30)
            , Margin.bottom Margin.auto
            ]
        , Box.visibility Box.visible
        , Box.opacity 0.9
        , Box.zIndex 1000
        , Box.cursor Cursor.default
        , Box.outline
            [ Outline.none ]
        , Box.background
            [ Elegant.color Color.blue
            , Background.images
                [ Background.image "https://hackage.haskell.org/package/elm-reactor-0.3.1/src/assets/favicon.ico"
                    |> Background.at ( px 5, px 5 )
                , Background.linear (Background.degree 90)
                    (Background.colorStop Color.blue |> Background.at (px 4))
                    (Background.colorStop Color.black)
                    |> Background.intermediateColors [ Background.colorStop Color.red ]
                    |> Background.gradient
                    |> Background.at ( px 30, px 30 )
                , Background.radial
                    (Background.colorStop Color.black |> Background.at (px 200))
                    (Background.colorStop Color.blue)
                    |> Background.gradient
                ]
            ]
        , Box.position Position.static
        , Box.position <|
            Position.fixed
                [ Position.top (px 30)
                , Position.bottom (px 20)
                ]
        ]


toStyle : Display.DisplayBox -> Html.Attribute msg
toStyle =
    Elegant.style
        >> Elegant.toInlineStyles
        >> Html.Attributes.style