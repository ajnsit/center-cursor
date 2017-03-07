{CompositeDisposable} = require 'atom'

module.exports = CenterCursor =
  modalPanel: null
  subscriptions: null
  editorSubscriptions: null
  timeout: null
  enabled: false

  activate: () ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'center-cursor:toggle': => @toggle()

  deactivate: ->
    # Dispose all handlers
    @subscriptions.dispose()
    @editorSubscriptions.dispose()

  enable: ->
    @enabled = true
    @editorSubscriptions = new CompositeDisposable

    # Register plugin for all editors (present and future)
    @editorSubscriptions.add atom.workspace.observeTextEditors (editor) =>
      @editorSubscriptions.add editor.onDidChangeCursorPosition @centerCursor

  disable: ->
    @enabled = false
    @editorSubscriptions.dispose()

  toggle: ->
    if @enabled
      @disable()
    else
      @enable()

  # Center the cursor by scrolling the view by an appropriate amount
  centerCursor: (event) ->
    cursor = event.cursor
    editor = cursor.editor
    view = atom.views.getView(editor)

    newPos = event.newBufferPosition.row
    halfScreen = Math.floor(editor.getRowsPerPage() / 2)
    newScrollTop = editor.getLineHeightInPixels() * (newPos - halfScreen)

    # Make sure any previously scheduled timeouts are cleared
    if @timeout
      clearTimeout(@timeout)

    # Scroll after a timeout
    # We could scroll synchronously but that doesn't work when you are typing
    # Because atom immediately overrides the scroll to perform its own scrolling
    @timeout = setTimeout (() ->
      view.setScrollTop newScrollTop
    ), 0
