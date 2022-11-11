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
      hlID = function() end,
    },
    tbl_extend = function(method, left, right)
      -- naive merge tables:
      local result = {}
      for k,v in pairs(right) do result[k] = v end
      for k,v in pairs(left) do result[k] = v end
      return result
    end,
  }
}
