module Analyser.Modules exposing (Modules, build, decode, empty, encode)

import Analyser.CodeBase exposing (CodeBase)
import Analyser.FileContext as FileContext exposing (FileContext)
import Analyser.Files.Types exposing (LoadedSourceFiles)
import Elm.Syntax.Base exposing (ModuleName)
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


decode : Decoder Modules
decode =
    JD.map2 Modules
        (JD.field "projectModules" (JD.list decodeModuleName))
        (JD.field "dependencies" (JD.list decodeDependency))


decodeDependency : Decoder ( ModuleName, ModuleName )
decodeDependency =
    JD.map2 (,)
        (JD.index 0 decodeModuleName)
        (JD.index 1 decodeModuleName)


decodeModuleName : Decoder ModuleName
decodeModuleName =
    JD.string |> JD.map (String.split ".")


encodeModuleName : ModuleName -> Value
encodeModuleName =
    String.join "." >> JE.string


encodeDependency : ( ModuleName, ModuleName ) -> Value
encodeDependency ( from, to ) =
    JE.list [ encodeModuleName from, encodeModuleName to ]


encode : Modules -> Value
encode modules =
    JE.object
        [ ( "projectModules", JE.list <| List.map encodeModuleName modules.projectModules )
        , ( "dependencies", JE.list <| List.map encodeDependency modules.dependencies )
        ]
