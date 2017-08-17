port module AnalyserPorts exposing (onFixMessage, onReset, sendMessagesAsJson, sendReport, sendStateAsJson)

import Analyser.Messages.Json as Messages
import Analyser.Messages.Types exposing (Message)
import Analyser.Report as Report exposing (Report)
import Analyser.State exposing (State, encodeState)
import Json.Encode as JE exposing (Value)


port sendReportValue : Value -> Cmd msg


port messagesAsJson : List String -> Cmd msg


port sendState : String -> Cmd msg


port onReset : (Bool -> msg) -> Sub msg


port onFixMessage : (Int -> msg) -> Sub msg


sendReport : Report -> Cmd msg
sendReport =
    sendReportValue << Report.encode


sendStateAsJson : State -> Cmd msg
sendStateAsJson =
    sendState << JE.encode 0 << encodeState


sendMessagesAsJson : List Message -> Cmd msg
sendMessagesAsJson =
    List.map Messages.serialiseMessage >> messagesAsJson
