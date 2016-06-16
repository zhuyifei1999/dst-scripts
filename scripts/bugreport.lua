local PopupDialogScreen = require "screens/popupdialog"
local SubmittingBugReportPopup = require "screens/submittingbugreportpopup"

function ShowBugReportPopup()

    local function onNo()
        TheFrontEnd:PopScreen()
    end

    local function onYes()
        TheFrontEnd:PopScreen()
        TheSystemService:FileBugReport("")
        local popup = SubmittingBugReportPopup()
        TheFrontEnd:PushScreen(popup)
    end

    local popup = PopupDialogScreen(
        STRINGS.UI.BUGREPORTSCREEN.SUBMIT_TITLE,
        STRINGS.UI.BUGREPORTSCREEN.SUBMIT_TEXT,
        {
            {text=STRINGS.UI.BUGREPORTSCREEN.NO, cb = onNo},
            {text=STRINGS.UI.BUGREPORTSCREEN.YES, cb = onYes},
        }
    )

    TheFrontEnd:PushScreen(popup)
end

