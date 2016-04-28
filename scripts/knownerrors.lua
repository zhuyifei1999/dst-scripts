
ERRORS = {
    CONFIG_DIR_WRITE_PERMISSION = {
        message = "Unable to write to config directory. Please make sure you have permissions for your Klei save folder.",
        url = "http://support.kleientertainment.com/customer/portal/articles/2409757",
    }
}

function known_assert(condition, key)
    if not condition then
        if ERRORS[key] ~= nil then
            known_error_key = key
            error(ERRORS[key].message, 2)
        else
            error(key, 2)
        end
    else
        return condition
    end
end
