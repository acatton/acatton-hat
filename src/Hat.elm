{- Copyright (c) 2015 Antoine Catton <devel at antoine dot catton dot fr>
 -
 - This work is free. You can redistribute it and/or modify it under the
 - terms of the Do What The Fuck You Want To Public License, Version 2,
 - as published by Sam Hocevar. See the LICENSE file for more details.
 -}

module Hat where

import List
import Json.Decode
import Random (..)
import Result
import Signal

import Html (..)
import Html.Attributes (..)
import Html.Events (..)


type alias Model =
    { typedName: String
    , inHat: List String
    , selected: Maybe String
    , previouslySelected: List String
    , seed: Seed
    }

type Action = TypedName String | AddName | PickAName | NoOp

update : Action -> Model -> Model
update action model =
    let addName model =
            case model.typedName of
                "" -> model
                _ ->
                    { model | typedName <- ""
                            , inHat <- model.typedName :: model.inHat
                            }
        pickAName model =
            let previouslySelected =
                    case model.selected of
                        Just name -> name :: model.previouslySelected
                        Nothing -> model.previouslySelected
                (name, inHat, seed) =
                    case model.inHat of
                        [] -> (Nothing, [], model.seed)
                        _ ->
                            let split n l = (List.take n l, List.drop n l)
                                getElem n l =
                                    let (start, elem :: end) = split n l in
                                    (elem, start ++ end)

                                maxIdx = (List.length model.inHat) - 1
                                (elemIdx, seed) = generate (int 0 maxIdx) model.seed
                                (name, inHat) = getElem elemIdx model.inHat
                            in (Just name, inHat, seed)
            in
            { model | inHat <- inHat
                    , selected <- name
                    , previouslySelected <- previouslySelected
                    , seed <- seed
                    }


    in
    case action of
        TypedName str -> { model | typedName <- str }
        AddName -> addName model
        PickAName -> pickAName model

-- Mostly stolen from:
-- <https://github.com/evancz/elm-todomvc/blob/master/Todo.elm>
onEnter : Signal.Message -> Attribute
onEnter message =
    let is13 code =
            if code == 13 then Ok () else Err "not the right key code"
        decoder = Json.Decode.customDecoder keyCode is13
    in on "keydown" decoder (always message)

view : Model -> Html
view model =
    let viewName name =
            li [] [text name]
        viewSelectedName selected =
            case selected of
                Just name -> [text name]
                Nothing -> []

        actionAddName = Signal.send actions AddName
        actionPickAName = Signal.send actions PickAName
        actionTypedName = Signal.send actions << TypedName
    in
    section []
        [ section []
            [ label [ for "hat-name" ] [ text "Name: " ]
            , input [ type' "text"
                    , id "hat-name"
                    , on "input" targetValue actionTypedName
                    , onEnter actionAddName
                    , value model.typedName
                    ] []
            , button [ onClick actionAddName, id "hat-add" ] [text "Add"]
            , button [ onClick actionPickAName, id "hat-pick" ] [text "Pick!"]
            , ul [] (List.map viewName model.inHat)
            ]
        , h1 [] (viewSelectedName model.selected)
        , section []
            [ h1 [] [text "Previously"]
            , ul [] (List.map viewName model.previouslySelected)
            ]
        ]

main : Signal Html
main = Signal.map view model

model : Signal Model
model =
    let init = { typedName = ""
               , inHat = []
               , selected = Nothing
               , previouslySelected = []
               , seed = initialSeed 1337 -- FIXME: Hardcoded seed
               }
    in Signal.foldp update init (Signal.subscribe actions)

actions : Signal.Channel Action
actions = Signal.channel NoOp
