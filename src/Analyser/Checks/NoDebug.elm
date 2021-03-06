module Analyser.Checks.NoDebug exposing (checker)

import ASTUtil.Inspector as Inspector exposing (Order(Post), defaultConfig)
import Analyser.Checks.Base exposing (Checker, keyBasedChecker)
import Analyser.Configuration as Configuration exposing (Configuration)
import Analyser.FileContext exposing (FileContext)
import Analyser.Messages.Range as Range exposing (Range, RangeContext)
import Analyser.Messages.Types exposing (Message, MessageData(DebugCrash, DebugLog), newMessage)
import Elm.Syntax.Expression exposing (..)


checker : Checker
checker =
    { check = scan
    , shouldCheck = keyBasedChecker [ "DebugLog", "DebugCrash" ]
    }


type DebugType
    = Log
    | Crash


type alias Context =
    List ( DebugType, Range )


scan : RangeContext -> FileContext -> Configuration -> List Message
scan rangeContext fileContext configuration =
    Inspector.inspect
        { defaultConfig | onExpression = Post (onExpression rangeContext) }
        fileContext.ast
        []
        |> List.filterMap (asMessage fileContext.path configuration)
        |> List.map (newMessage [ ( fileContext.sha1, fileContext.path ) ])


asMessage : String -> Configuration -> ( DebugType, Range ) -> Maybe MessageData
asMessage path configuration ( debugType, range ) =
    case debugType of
        Log ->
            if Configuration.checkEnabled "DebugLog" configuration then
                Just (DebugLog path range)
            else
                Nothing

        Crash ->
            if Configuration.checkEnabled "DebugCrash" configuration then
                Just (DebugCrash path range)
            else
                Nothing


onExpression : RangeContext -> Expression -> Context -> Context
onExpression rangeContext ( range, expression ) context =
    case expression of
        QualifiedExpr moduleName f ->
            entryForQualifiedExpr moduleName f
                |> Maybe.map (flip (,) (Range.build rangeContext range) >> flip (::) context)
                |> Maybe.withDefault context

        _ ->
            context


entryForQualifiedExpr : List String -> String -> Maybe DebugType
entryForQualifiedExpr moduleName f =
    if moduleName == [ "Debug" ] then
        if f == "log" then
            Just Log
        else if f == "crash" then
            Just Crash
        else
            Nothing
    else
        Nothing
