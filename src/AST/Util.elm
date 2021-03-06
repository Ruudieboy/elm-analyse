module AST.Util exposing (fileExposingList, fileModuleName, getParenthesized, isCase, isIf, isLambda, isLet, isOperatorApplication, isPortModule, moduleExposingList, patternModuleNames)

import Elm.Syntax.Base exposing (ModuleName)
import Elm.Syntax.Exposing exposing (..)
import Elm.Syntax.Expression exposing (Expression, InnerExpression(CaseExpression, IfBlock, LambdaExpression, LetExpression, OperatorApplication, ParenthesizedExpression))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module exposing (Module(EffectModule, NoModule, NormalModule, PortModule))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Range)


moduleExposingList : Module -> Exposing TopLevelExpose
moduleExposingList m =
    case m of
        NormalModule x ->
            x.exposingList

        PortModule x ->
            x.exposingList

        EffectModule x ->
            x.exposingList

        NoModule ->
            None


isPortModule : File -> Bool
isPortModule file =
    case file.moduleDefinition of
        PortModule _ ->
            True

        _ ->
            False


fileExposingList : File -> Maybe (Exposing TopLevelExpose)
fileExposingList file =
    case file.moduleDefinition of
        NormalModule x ->
            Just x.exposingList

        PortModule x ->
            Just x.exposingList

        EffectModule x ->
            Just x.exposingList

        NoModule ->
            Nothing


fileModuleName : File -> Maybe ModuleName
fileModuleName file =
    case file.moduleDefinition of
        NormalModule x ->
            Just x.moduleName

        PortModule x ->
            Just x.moduleName

        EffectModule x ->
            Just x.moduleName

        NoModule ->
            Nothing


isLambda : Expression -> Bool
isLambda ( _, e ) =
    case e of
        LambdaExpression _ ->
            True

        _ ->
            False


isLet : Expression -> Bool
isLet ( _, e ) =
    case e of
        LetExpression _ ->
            True

        _ ->
            False


isIf : Expression -> Bool
isIf ( _, e ) =
    case e of
        IfBlock _ _ _ ->
            True

        _ ->
            False


isCase : Expression -> Bool
isCase ( _, e ) =
    case e of
        CaseExpression _ ->
            True

        _ ->
            False


isOperatorApplication : Expression -> Bool
isOperatorApplication ( _, e ) =
    case e of
        OperatorApplication _ _ _ _ ->
            True

        _ ->
            False


getParenthesized : Expression -> Maybe ( Range, Expression )
getParenthesized ( r, e ) =
    case e of
        ParenthesizedExpression p ->
            Just ( r, p )

        _ ->
            Nothing


patternModuleNames : Pattern -> List ModuleName
patternModuleNames p =
    case p of
        TuplePattern xs _ ->
            List.concatMap patternModuleNames xs

        RecordPattern _ _ ->
            []

        UnConsPattern left right _ ->
            patternModuleNames left ++ patternModuleNames right

        ListPattern xs _ ->
            List.concatMap patternModuleNames xs

        NamedPattern qualifiedNameRef subPatterns _ ->
            qualifiedNameRef.moduleName :: List.concatMap patternModuleNames subPatterns

        QualifiedNamePattern qualifiedNameRef _ ->
            [ qualifiedNameRef.moduleName ]

        AsPattern inner _ _ ->
            patternModuleNames inner

        ParenthesizedPattern inner _ ->
            patternModuleNames inner

        _ ->
            []
