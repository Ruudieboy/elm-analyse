module Analyser.Modules exposing (Modules, build, codec, empty)

import Analyser.CodeBase exposing (CodeBase)
import Analyser.FileContext as FileContext exposing (FileContext)
import Analyser.Files.Types exposing (LoadedSourceFiles)
import Elm.Syntax.Base exposing (ModuleName)
import Json.Bidirectional as JB
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)


type alias Modules =
    { projectModules : List ModuleName
    , dependencies : List ( ModuleName, ModuleName )
    }


empty : Modules
empty =
    { projectModules = []
    , dependencies = []
    }


build : CodeBase -> LoadedSourceFiles -> Modules
build codeBase sources =
    let
        files =
            FileContext.build codeBase sources
    in
    { projectModules = List.filterMap .moduleName files
    , dependencies = List.concatMap edgesInFile files
    }


edgesInFile : FileContext -> List ( List String, List String )
edgesInFile file =
    case file.moduleName of
        Just moduleName ->
            file.ast.imports
                |> List.map .moduleName
                |> List.map ((,) moduleName)

        Nothing ->
            []


codec : JB.Coder Modules
codec =
    JB.object Modules
        |> JB.withField "projectModules" .projectModules (JB.list moduleNameCoder)
        |> JB.withField "dependencies" .dependencies (JB.list dependencyCoder)


dependencyCoder : JB.Coder ( ModuleName, ModuleName )
dependencyCoder =
    JB.tuple ( moduleNameCoder, moduleNameCoder )


moduleNameCoder : JB.Coder ModuleName
moduleNameCoder =
    JB.custom encodeModuleName decodeModuleName


decodeModuleName : Decoder ModuleName
decodeModuleName =
    JD.string |> JD.map (String.split ".")


encodeModuleName : ModuleName -> Value
encodeModuleName =
    String.join "." >> JE.string
