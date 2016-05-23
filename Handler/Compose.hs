module Handler.Compose where

import Import
import Widget.Editor (editorWidget, footerWidget)
import Widget.Languages (languagesWidget)
import Util.Handler (maybeApiUser, title, titleConcat, urlDecode', apiRequestHeaders)
import Util.Snippet (persistRunParams)
import Util.Alert (successHtml)
import Network.Wai (lazyRequestBody)
import Model.Snippet.Api (addSnippet)

getComposeLanguagesR :: Handler Html
getComposeLanguagesR = do
    defaultLayout $ do
        setTitle $ title "New snippet - Choose language"
        $(widgetFile "new")

getComposeR :: Language -> Handler Html
getComposeR lang = do
    let snippet = defaultSnippet lang
    defaultLayout $ do
        setTitle $ titleConcat ["New ", languageName lang, " Snippet"]
        $(widgetFile "compose")

postComposeR :: Language -> Handler Value
postComposeR _ = do
    langVersion <- fromMaybe "latest" <$> lookupGetParam "version"
    runCommand <- urlDecode' <$> fromMaybe "" <$> lookupGetParam "command"
    stdinData <- urlDecode' <$> fromMaybe "" <$> lookupGetParam "stdin"
    req <- reqWaiRequest <$> getRequest
    body <- liftIO $ lazyRequestBody req
    mUserId <- maybeAuthId
    mApiUser <- maybeApiUser mUserId
    let authToken = apiUserToken <$> mApiUser
    let headers = apiRequestHeaders req authToken
    snippet <- liftIO $ addSnippet body headers
    persistRunParams (snippetId snippet) stdinData langVersion runCommand
    renderUrl <- getUrlRender
    setMessage $ successHtml "Saved snippet"
    let url = renderUrl $ SnippetR $ snippetId snippet
    return $ object ["url" .= url]


defaultSnippet :: Language -> Snippet
defaultSnippet lang =
    Snippet{
        snippetId="",
        snippetLanguage=pack $ show lang,
        snippetTitle="Untitled",
        snippetPublic=True,
        snippetOwner="",
        snippetFilesHash="",
        snippetModified="",
        snippetCreated="",
        snippetFiles=defaultSnippetFiles lang
    }

defaultSnippetFiles :: Language -> [SnippetFile]
defaultSnippetFiles lang =
    [SnippetFile{
        snippetFileName=languageDefaultFname lang,
        snippetFileContent=pack $ languageDefaultContent lang
    }]
