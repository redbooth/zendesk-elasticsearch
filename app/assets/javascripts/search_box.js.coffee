window.SearchBox = (box_id, spinner_parent_id, result_div_id) ->

  prev_timeout = null
  has_been_used = false
  last_text = ''
  spinner_target = document.getElementById(spinner_parent_id.split('#').pop())

  #update the child select box
  update_on_load = (event) ->
    # get the text 
    text = $(event.target).val()
    params = {"text": text}

    if (text is '' and !has_been_used) or text is last_text
      return

    # mark the box as having been used
    has_been_used = true

    # save the query off
    last_text = text

    # clear the results
    $(result_div_id).html('')
    
    # start the progress indicator
    spinner = new Spinner().spin(spinner_target)
    
    # evaluate the search
    $.get('/index/find_tickets', params)
    .always( () ->
      # stop the spinner
      spinner.stop()
    )


  # return a hash with the event handling function
  {
    setup: ()->
      $(box_id).keyup( (event) ->
        if prev_timeout?
          clearTimeout(prev_timeout)
        prev_timeout = setTimeout( update_on_load, 300, event)
        false
      )
      null
  }