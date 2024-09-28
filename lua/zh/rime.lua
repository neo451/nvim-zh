---@diagnostic disable: inject-field
local ffi = require "ffi"

ffi.cdef [[
typedef struct rime_traits_t {
  int data_size;
  // v0.9
  const char* shared_data_dir;
  const char* user_data_dir;
  const char* distribution_name;
  const char* distribution_code_name;
  const char* distribution_version;
  // v1.0
  /*!
   * Pass a C-string constant in the format "rime.x"
   * where 'x' is the name of your application.
   * Add prefix "rime." to ensure old log files are automatically cleaned.
   */
  const char* app_name;

  //! A list of modules to load before initializing
  const char** modules;
  // v1.6
  /*! Minimal level of logged messages.
   *  Value is passed to Glog library using FLAGS_minloglevel variable.
   *  0 = INFO (default), 1 = WARNING, 2 = ERROR, 3 = FATAL
   */
  int min_log_level;
  /*! Directory of log files.
   *  Value is passed to Glog library using FLAGS_log_dir variable.
   *  NULL means temporary directory, and "" means only writing to stderr.
   */
  const char* log_dir;
  //! prebuilt data directory. defaults to ${shared_data_dir}/build
  const char* prebuilt_data_dir;
  //! staging directory. defaults to ${user_data_dir}/build
  const char* staging_dir;
} RimeTraits;

typedef struct rime_schema_list_item_t {
  char* schema_id;
  char* name;
  void* reserved;
} RimeSchemaListItem;

typedef struct rime_schema_list_t {
  size_t size;
  RimeSchemaListItem* list;
} RimeSchemaList;

typedef uintptr_t RimeSessionId;

void RimeSetup(RimeTraits* traits);
void RimeInitialize(RimeTraits* traits);
void RimeFinalize(void);

// session management

RimeSessionId (*create_session)(void);
bool (*find_session)(RimeSessionId session_id);
bool (*destroy_session)(RimeSessionId session_id);
void (*cleanup_stale_sessions)(void);
void (*cleanup_all_sessions)(void);

bool RimeDestroySession(RimeSessionId session_id);

RimeSessionId RimeCreateSession();
bool RimeGetCurrentSchema(RimeSessionId session_id, char* schema_id, size_t buffer_size);
bool RimeGetSchemaList(RimeSchemaList* output);
]]

local librime = ffi.load "librime.so"

local M = {}

local default = {
   shared_data_dir = "/usr/share/rime-data",
   user_data_dir = "/home/n451/.local/share/rime-ls",
   log_dir = "/home/n451/.local/share/nvim/rime",
   distribution_name = "Rime",
   distribution_code_name = "nvim-rime",
   distribution_version = "0.0.1",
   app_name = "rime.nvim-rime",
   min_log_level = 3,
}

function M.init(traits_cfg)
   traits_cfg = traits_cfg or default
   local traits = ffi.new [[RimeTraits]]
   for k, v in pairs(traits_cfg) do
      traits[k] = v
   end
   librime.RimeSetup(traits)
   librime.RimeInitialize(traits)
end

function M.finalize()
   librime.RimeFinalize()
end

---@return integer|unknown
function M.createSession()
   local session_id = librime.RimeCreateSession()
   if session_id == 0 then
      print "cannot create session"
   end
   return session_id
end

---@param session_id integer
---@return boolean
function M.destroySession(session_id)
   local ret = librime.RimeDestroySession(session_id)
   print(ret)
   return ret
end

---@param session_id integer
function M.getCurrentSchema(session_id) end

M.init(default)
-- id = M.createSession()
-- M.destroySession(id)
-- M.finalize()

return M
