*   Allow the use of callable objects as group methods for grouped selects.

    Until now, the `option_groups_from_collection_for_select` method was only able to
    handle method names as `group_method` and `group_label_method` parameters,
    it is now able to receive procs and other callable objects too.

    *Jérémie Bonal*

*   Add `preload_link_tag` helper

    This helper that allows to the browser to initiate early fetch of resources
    (different to the specified in `javascript_include_tag` and `stylesheet_link_tag`).
    Additionally, this sends Early Hints if supported by browser.

    *Guillermo Iguaran*

## Rails 5.2.0.beta2 (November 28, 2017) ##

*   No changes.


## Rails 5.2.0.beta1 (November 27, 2017) ##

*   Change `form_with` to generates ids by default.

    When `form_with` was introduced we disabled the automatic generation of ids
    that was enabled in `form_for`. This usually is not an good idea since labels don't work
    when the input doesn't have an id and it made harder to test with Capybara.

    You can still disable the automatic generation of ids setting `config.action_view.form_with_generates_ids`
    to `false.`

    *Nick Pezza*

*   Fix issues with `field_error_proc` wrapping `optgroup` and select divider `option`.

    Fixes #31088

    *Matthias Neumayr*

*   Remove deprecated Erubis ERB handler.

    *Rafael Mendonça França*

*   Remove default `alt` text generation.

    Fixes #30096

    *Cameron Cundiff*

*   Add `srcset` option to `image_tag` helper.

    *Roberto Miranda*

*   Fix issues with scopes and engine on `current_page?` method.

    Fixes #29401.

    *Nikita Savrov*

*   Generate field ids in `collection_check_boxes` and `collection_radio_buttons`.

    This makes sure that the labels are linked up with the fields.

    Fixes #29014.

    *Yuji Yaginuma*

*   Add `:json` type to `auto_discovery_link_tag` to support [JSON Feeds](https://jsonfeed.org/version/1)

    *Mike Gunderloy*

*   Update `distance_of_time_in_words` helper to display better error messages
    for bad input.

    *Jay Hayes*


Please check [5-1-stable](https://github.com/rails/rails/blob/5-1-stable/actionview/CHANGELOG.md) for previous changes.
