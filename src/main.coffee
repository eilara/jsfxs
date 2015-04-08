diskOutdated = false
renderOutdated = true

textarea = undefined
outputarea = undefined
filePicker = undefined

window.addEventListener 'beforeunload', (e) ->
  if diskOutdated
    e.returnValue = 'Are you sure you want to leave this page?'

code = """
       var alert = function() fx[dom] {
           // alert has an effect on the dom
       }
       var startWorker = function(func fx[!dom]) {
           // startWorker expects a function argument without dom effects
       }
       var obj = {f: function() { } }; // object with harmless function f
       var box = function (x) {
           return function() { return x; } // closure which holds on to 'x'
       };
       var b = box(obj);
       startWorker(function() {
           b().f(); // unboxing 'b' and calling the function in 'f'
       });
       obj.f = alert;  // <- causes a contract violation in the worker
       """

window.App =
  init: ->
    CodeMirror.extendMode 'javascript', token: (stream, state) ->
      if stream.match 'fx', false
        @_token stream, state
        'keyword'
      else
        @_token stream, state
    textarea = CodeMirror $('#source .panel-body').get(0),
      value: code
      mode: 'javascript'
      indentUnit: 4

    $('#loadButton').click(load)
    filePicker = $('#filePicker')
    filePicker.on('change', load2)

    $('#saveButton').click(save)

    textarea.on 'change', ->
      $('#source .panel').removeClass 'panel-danger'
      $('#source .panel').removeClass 'panel-success'
      $('#source .panel').addClass 'panel-warning'
      $('#msg').html 'Checking...'
      possiblyUpdate()

    $('#vimmode').on 'change', ->
      console.log $('#vimmode').is(':checked')
      textarea.setOption 'vimMode', $('#vimmode').is(':checked')


update = ->
  code = textarea.getValue()
  $('#source .panel').removeClass 'panel-warning'
  analyze()

possiblyUpdate = _.debounce update, 2000

analyze = ->
  $.post 'compile', code: code, (data) ->
    if data.success
      $('#msg').html 'All contracts satisfied.'
      $('#source .panel').addClass 'panel-success'
    else
      $('#msg').html 'Found a contract violation!'
      $('#source .panel').addClass 'panel-danger'

load = ->
  if diskOutdated
    if !window.confirm('Are you sure you want to load a new file without' +
                       'saving this one first?')
      return
  filePicker[0].click()

load2 = ->
  file = filePicker[0].files[0]
  if file == undefined
    console.log('file is undefined')
    return
  reader = new FileReader()
  reader.onload = (_) ->
    if reader.result == undefined
      console.log('file contents are undefined')
      return

    # Populate the text field with the new source code
    code = reader.result
    textarea.setValue(reader.result)
    diskOutdated = false
    renderOutdated = true

  reader.readAsText(file)

save = ->
  console.log('attempting to save')
  download('file.ctm', textarea.getValue())

download = (filename, text) ->
  a = $('<a>')
  a.attr
    href: 'data:text/plain;charset=utf-8,' + encodeURIComponent(text)
    download: filename
  a.appendTo($('body'))
  a[0].click()
  a.remove()
  diskOutdated = false
