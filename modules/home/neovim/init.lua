local bootstrap = require("bootstrap")

if type(bootstrap) == "table" and type(bootstrap.bootstrap) == "function" then
  bootstrap.bootstrap()
else
  error("Bootstrap module is not in the expected format")
end
