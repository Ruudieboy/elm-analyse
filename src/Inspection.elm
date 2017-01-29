module Inspection exposing (run)

import Analyser.FileContext as FileContext
import Analyser.LoadedDependencies exposing (LoadedDependencies)
import Analyser.Messages exposing (Message)
import Analyser.Types exposing (LoadedSourceFiles)
import Analyser.Checks.UnusedVariable as UnusedVariable
import Analyser.Checks.NotExposeAll as NotExposeAll


run : LoadedSourceFiles -> LoadedDependencies -> List Message
run source deps =
    let
        checks =
            [ UnusedVariable.scan
            , NotExposeAll.scan
            ]

        messages =
            source
                |> List.filterMap (FileContext.create source deps)
                |> List.concatMap (\x -> List.concatMap ((|>) x) checks)
    in
        messages
