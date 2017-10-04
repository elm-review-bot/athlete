module Main exposing (..)

import Html exposing (Html)
import Html.Attributes
import Elegant exposing (px)
import Typography
import Typography.Character
import Color exposing (Color)

main : Html msg
main =
  Html.div
    [ Html.Attributes.style
      <| Elegant.toInlineStyles
      <| flip Elegant.style []
      <| Just
      <| Elegant.displayBlock []
        [ Elegant.typography
          [ Elegant.color Color.blue
          , Typography.character
            [ Typography.Character.weight 900
            , Typography.Character.size (px 200)
            , Typography.Character.italic
            ]
          ]
        , Elegant.padding (px 30)
        ]
    ]
    [ Html.text "Just a text." ]
