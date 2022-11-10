return {
  vim_mock = {
    api = {
      nvim_exec = function()
        return "exec-id"
      end
    },
    fn = {
      synIDattr = function(_id, attrib)
        if attrib == "bg" then
          return "Orange"
        end
        return ""
      end,
      synIDtrans = function() end,
      hlID = function() end
    }
  }
}
