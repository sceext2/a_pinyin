# op.coffee, a_pinyin/apk/src/redux/

path = require 'path'

{
  Alert
  Clipboard
} = require 'react-native'
{ default: RNFetchBlob } = require 'react-native-fetch-blob'

action = require './action'
util = require '../util'

config = require '../config'
im_native = require '../im_native'
{
  KB_FONT_SIZE
} = require '../style'


close_window = ->
  (dispatch, getState) ->
    await im_native.close_window()

add_text = (text, mode = 0) ->
  (dispatch, getState) ->
    await im_native.add_text(text, mode)

add_text_pinyin = (text, pinyin) ->
  (dispatch, getState) ->
    await im_native.add_text(text, im_native.INPUT_MODE_PINYIN, pinyin)

key_delete = ->
  (dispatch, getState) ->
    await im_native.key_delete()

key_enter = ->
  (dispatch, getState) ->
    await im_native.key_enter()

clip_paste = ->
  (dispatch, getState) ->
    s = await Clipboard.getString()
    if ! s?
      return  # null string
    if s.length < 1
      return  # empty string
    # input the string from clipboard (paste function)
    await dispatch add_text(s)  # mode = 0, nolog

# for pinyin input

reset_pinyin = ->
  (dispatch, getState) ->
    dispatch action.pinyin_reset()
    await im_native.set_pinyin(null)

_pinyin_commit = ->
  (dispatch, getState) ->
    $$p = getState().get 'pinyin'
    text = $$p.get('wait').toJS().join('')
    # FIXME use first cut result
    pinyin = $$p.getIn(['cut', 0]).toJS().pinyin
    await dispatch add_text_pinyin(text, pinyin)
    await dispatch reset_pinyin()

# use core_get_text()
_update_can = ->
  (dispatch, getState) ->
    $$p = getState().get 'pinyin'
    wait = $$p.get('wait').toJS().join('')  # wait chars
    cut = $$p.get('cut').toJS()
    # check empty cut
    if cut.length < 1
      dispatch action.pinyin_set({
        can: []  # use empty can here
      })
      return
    # FIXME use first cut result
    cr = cut[0]
    # get rest pinyin
    pinyin = cr.pinyin[wait.length ..]
    if pinyin.length > 0
      can = await im_native.core_get_text(pinyin)
      dispatch action.pinyin_set({
        can
      })
    # else: FIXME what to do ?

# render top pinyin str
_update_top_pinyin = ->
  (dispatch, getState) ->
    $$p = getState().get 'pinyin'
    wait = $$p.get('wait').toJS().join('')
    cut = $$p.get('cut').toJS()
    # check empty cut
    if cut.length < 1
      # just use raw user input
      raw = $$p.get 'raw'
      await im_native.set_pinyin(raw)
      return
    # FIXME use first cut result
    cr = cut[0]
    # get rest pinyin
    pinyin = cr.pinyin[wait.length ..]

    # merge result
    o = wait + pinyin.join('\'')
    # check rest
    if cr.rest?
      o += '\'' + cr.rest
    # check add last `'` char in raw input
    raw = $$p.get 'raw'
    if raw[raw.length - 1] is '\''
      o += '\''

    await im_native.set_pinyin(o)

_update_pinyin = (new_pinyin) ->
  (dispatch, getState) ->
    # check empty pinyin
    if new_pinyin.length < 1
      await dispatch reset_pinyin()
      return

    # cut pinyin
    cut = await im_native.core_pinyin_cut(new_pinyin)
    dispatch action.pinyin_set({
      raw: new_pinyin
      cut
    })

    await dispatch _update_can()
    await dispatch _update_top_pinyin()

# low level user raw input: add_char, delete, select_item
pinyin_add_char = (c) ->
  (dispatch, getState) ->
    old_pinyin = getState().getIn ['pinyin', 'raw']
    new_pinyin = old_pinyin + c

    # TODO add pinyin char if wait is not empty ?
    await dispatch _update_pinyin(new_pinyin)

pinyin_delete = ->
  (dispatch, getState) ->
    # check no pinyin, then just pass-through delete key
    old_pinyin = getState().getIn ['pinyin', 'raw']
    if old_pinyin.length < 1
      await dispatch key_delete()
      return

    # check wait chars, delete wait first
    wait = getState().getIn(['pinyin', 'wait']).toJS()
    if wait.length > 0
      wait.pop()  # delete last part of wait chars
      dispatch action.pinyin_set({
        wait
      })
      await dispatch _update_can()
      await dispatch _update_top_pinyin()
      return

    # no wait chars, now delete pinyin (remove last char)
    new_pinyin = old_pinyin[... old_pinyin.length - 1]
    await dispatch _update_pinyin(new_pinyin)

pinyin_select_item = (text) ->
  (dispatch, getState) ->
    wait = getState().getIn(['pinyin', 'wait']).toJS()
    wait.push text
    dispatch action.pinyin_set({
      wait
    })
    # check commit text
    # assert: cut can not be empty
    # FIXME use first cut result
    cr = getState().getIn(['pinyin', 'cut', 0]).toJS()
    wait_text = wait.join('')
    if (! cr.rest?) and (wait_text.length >= cr.pinyin.length)
      # no rest pinyin, should commit
      await dispatch _pinyin_commit()
    else
      await dispatch _update_can()
      await dispatch _update_top_pinyin()

# process press space key in pinyin keyboard
pinyin_space = ->
  (dispatch, getState) ->
    $$p = getState().get 'pinyin'
    raw = $$p.get 'raw'

    if raw.length > 0
      can = $$p.get('can').toJS()
      # check has can items
      if (can.length > 0) and (can[0].length > 0)
        await dispatch pinyin_select_item(can[0][0])
      # else: ignore  # FIXME change this, not ignore ?
    else  # not in pinyin input state, send normal space char
      await dispatch add_text(' ')


# process native events

# native event send from both
# FIXME one event call this twice
on_native_event = (event) ->
  (dispatch, getState) ->
    # check event type
    switch event.type
      when 'core_start_input'
        await dispatch action.core_is_input(true, event.payload.mode)
      when 'core_end_input'
        await dispatch action.core_is_input(false, null)
        # reload symbols data here
        await dispatch load_user_symbol()
        await dispatch load_user_symbol2()
      when 'core_nolog_mode_change'
        # get new mode
        nolog = await im_native.core_get_nolog()
        await dispatch action.core_nolog_change(nolog)

# native event from main Activity
on_native_event_ui = (event) ->
  (dispatch, getState) ->
    await dispatch on_native_event(event)
    # TODO
    await return

# native event from keyboard view
on_native_event_kb = (event) ->
  (dispatch, getState) ->
    await dispatch on_native_event(event)
    # TODO
    await return

core_set_nolog = (nolog) ->
  (dispatch, getState) ->
    await im_native.core_set_nolog(nolog)


# user model

load_user_symbol = ->
  (dispatch, getState) ->
    raw = await im_native.core_get_symbol()
    dispatch action.user_set_symbol(_calc_user_symbol(raw))

load_user_symbol2 = ->
  (dispatch, getState) ->
    raw = await im_native.core_get_symbol2()
    symbol2 = _calc_user_symbol2 raw
    # measure text width
    $$user = getState().get 'user'
    width = await _measure_symbol2 {
      old_symbol2: $$user.get('symbol2').toJS()
      old_width: $$user.get('measured_width').toJS()
      symbol2
    }
    # update symbol2 and text width
    dispatch action.user_set_symbol2(symbol2)
    dispatch action.user_set_measured_width(width)

_calc_user_symbol = (raw) ->
  # default list
  d = []
  for c in config.SYMBOL_DEFAULT
    d.push c
  # first list: order by last_used
  first = raw[0][0... config.SYMBOL_N]
  # second list: order by count
  _merge_list [first, raw[1], d]

_calc_user_symbol2 = (raw) ->
  first = raw[1][0... config.SYMBOL2_N]
  _merge_list [first, raw[2], raw[0]]

_merge_list = (raw) ->
  d = {}  # used items
  o = []
  for i in raw
    for j in i
      if ! d[j]
        o.push j
        d[j] = true
  o

_measure_symbol2 = (args) ->
  {
    old_symbol2
    old_width
    symbol2
  } = args
  # calc with cache
  cache = {}  # build old cache
  for i in [0... old_symbol2.length]
    # assert: old_symbol2.length == old_width.length
    cache[old_symbol2[i]] = old_width[i]
  # new items to measure
  to = []
  for i in symbol2
    if ! cache[i]?
      to.push i
  # measure text width and merge back to cache
  if to.length > 0
    fontSize = KB_FONT_SIZE
    height = 100  # TODO
    r = await util.measure_text_width to, fontSize, height
    for i in [0... to.length]
      cache[to[i]] = r[i]
  # gen new output
  o = []
  for i in symbol2
    o.push cache[i]
  o  # measure width done

# database

check_db = ->
  (dispatch, getState) ->
    ok = true
    # check core_data.db, path and size
    if await RNFetchBlob.fs.exists(config.DB_CORE_DATA)
      stat = await RNFetchBlob.fs.stat(config.DB_CORE_DATA)
      o = {}
      o[im_native.CORE_DATA_DB_NAME] = {
        path: config.DB_CORE_DATA
        size: stat.size
      }
      dispatch action.db_set_info(o)
    else
      ok = false
    # check user_data.db, path and size
    if await RNFetchBlob.fs.exists(config.DB_USER_DATA)
      stat = await RNFetchBlob.fs.stat(config.DB_USER_DATA)
      o = {}
      o[im_native.USER_DATA_DB_NAME] = {
        path: config.DB_USER_DATA
        size: stat.size
      }
      dispatch action.db_set_info(o)
    else
      ok = false
    # use im_native
    r = await im_native.core_get_db_info()
    o = {}
    i = r[im_native.CORE_DATA_DB_NAME]
    if i?
      o[im_native.CORE_DATA_DB_NAME] = {
        db_version: i.db_version
        db_type: i.db_type
        data_version: i.data_version
        last_update: i.last_update
      }
    i = r[im_native.USER_DATA_DB_NAME]
    if i?
      o[im_native.USER_DATA_DB_NAME] = {
        db_version: i.db_version
        db_type: i.db_type
        data_version: i.data_version
        last_update: i.last_update
      }
    dispatch action.db_set_info(o)
    # TODO check db version ?
    dispatch action.db_set_info({
      ok
    })
    # show alert if db is error
    if ! ok
      await dispatch _show_alert()

_show_alert = ->
  (dispatch, getState) ->
    new Promise (resolve) ->
      on_cancel = ->
        # nothing to do
        resolve false
      on_ok = ->
        dispatch dl_db()
        resolve true
      Alert.alert '数据库错误或不存在 !', '需要下载数据库, A拼音 才能正常工作.', [
        { text: '取消', onPress: on_cancel, style: 'cancel' }
        { text: '下载', onPress: on_ok }
      ], { cancelable: false }

dl_db = ->
  (dispatch, getState) ->
    dispatch action.db_set_info({
      dling: true
    })
    try
      await dispatch _dl_db()
      await dispatch check_db()
    catch e
      # TODO error process ?
    dispatch action.db_set_info({
      dling: false
    })

_dl_db = ->
  (dispatch, getState) ->
    mirror = getState().get 'dl_mirror'

    # core_data.db
    if ! await RNFetchBlob.fs.exists(config.DB_CORE_DATA)
      await _dl_one_db config.DB_CORE_DATA, config.DB_REMOTE_URL[mirror]['core_data.db'], " core_data.db A拼音 核心数据库 (#{mirror})"
    # user_data.db
    if ! await RNFetchBlob.fs.exists(config.DB_USER_DATA)
      await _dl_one_db config.DB_USER_DATA, config.DB_REMOTE_URL[mirror]['user_data.db'], " user_data.db A拼音 用户数据库 (#{mirror})"

_ensure_parent_dir = (p) ->
  parent = path.dirname(p)
  # ensure parent first
  if ! await RNFetchBlob.fs.isDir(parent)
    await _ensure_parent_dir parent
  # check and create this
  if ! await RNFetchBlob.fs.isDir(p)
    await RNFetchBlob.fs.mkdir(p)

_dl_one_db = (local_file, url, description) ->
  # check and create tmp dir
  await _ensure_parent_dir(config.DB_TMP_DIR)
  # use Android download manager to download the database file
  o = RNFetchBlob.config({
    addAndroidDownloads: {
      useDownloadManager: true
      notification: true
      mime: '*/*'
      title: description
      description
      path: path.join RNFetchBlob.fs.dirs.DownloadDir, path.basename(local_file)
    }
  })
  res = await o.fetch 'GET', url
  p = res.path()
  # check and create db dir
  await _ensure_parent_dir path.dirname(local_file)
  # write-replace the db file
  tmp_file = local_file + config.DB_TMP_SUFFIX
  await RNFetchBlob.fs.cp p, tmp_file  # write
  await RNFetchBlob.fs.mv tmp_file, local_file  # replace
  # try to delete download file, ignore error
  try
    await RNFetchBlob.fs.unlink p
  catch e
    # TODO ignore error

# core config

load_core_config = ->
  (dispatch, getState) ->
    # core level
    core_level = await im_native.core_config_get_level()
    dispatch action.update_config({
      core_level
    })

set_core_level = (level) ->
  (dispatch, getState) ->
    await im_native.core_config_set_level level
    await dispatch load_core_config()

clean_user_db = ->
  (dispatch, getState) ->
    dispatch action.db_set_info({
      cleaning: true
    })
    try
      await im_native.core_clean_user_db()
      # clean OK
      util.toast "整理完成."
    catch e
      # TODO more error info ?
      util.toast "数据库整理失败 !"
    # end doing
    dispatch action.db_set_info({
      cleaning: false
    })
    # reload db info
    await dispatch check_db()

exit_app = ->
  (dispatch, getState) ->
    await im_native.exit_app()

# data_user_symbol2

dus2_load = ->
  (dispatch, getState) ->
    # TODO error process ?
    dispatch action.dus2_load_start()
    result = await im_native.dus2_list()
    dispatch action.dus2_load_end(result)

dus2_add = (text) ->
  (dispatch, getState) ->
    await im_native.dus2_add(text)
    await dispatch dus2_load()

dus2_rm = (list) ->
  (dispatch, getState) ->
    await im_native.dus2_rm(list)
    await dispatch dus2_load()

module.exports = {
  close_window  # thunk
  add_text  # thunk
  add_text_pinyin  # thunk
  key_delete  # thunk
  key_enter  # thunk
  clip_paste  # thunk

  reset_pinyin  # thunk
  pinyin_add_char  # thunk
  pinyin_delete  # thunk
  pinyin_select_item  # thunk
  pinyin_space  # thunk

  on_native_event  # thunk
  on_native_event_ui  # thunk
  on_native_event_kb  # thunk

  core_set_nolog  # thunk

  load_user_symbol  # thunk
  load_user_symbol2  # thunk

  check_db  # thunk
  dl_db  # thunk

  load_core_config  # thunk
  set_core_level  # thunk

  clean_user_db  # thunk
  exit_app  # thunk

  dus2_load  # thunk
  dus2_add  # thunk
  dus2_rm  # thunk
}
