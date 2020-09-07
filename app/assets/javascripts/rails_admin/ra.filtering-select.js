/*
 * RailsAdmin filtering select @VERSION
 *
 * Based on the combobox example from jQuery UI documentation
 * http://jqueryui.com/demos/autocomplete/#combobox
 *
 * License
 *
 * http://www.railsadmin.org
 *
 * Depends:
 *   jquery.ui.core.js
 *   jquery.ui.widget.js
 *   jquery.ui.autocomplete.js
 */
(function($) {
  $.widget("ra.filteringSelect", {
    options: {
      createQuery: function(query, dependOnVal, object_id) {
        return { query: query, depend_on_val : dependOnVal, object_id : object_id };
      },
      minLength: 0,
      searchDelay: 200,
      remote_source: null,
      source: null,
      xhr: false
    },

    _create: function() {
      var self = this,
        select = this.element.hide(),
        selected = select.children(":selected"),
        value = selected.val() ? selected.text() : "";

      if (this.options.xhr) {
        this.options.source = this.options.remote_source;
      } else {
        this.options.source = select.children("option").map(function() {
          var dependOn = $(this).data("dependOn");
          if(dependOn && dependOn.match(/{index}/)) {
            var index = $(this).parents("select").attr("name").match(/[(\d+)]/)[0];
            dependOn = dependOn.replace("{index}", index)
          }
          return { label: $(this).text(), value: this.value,
                   dependOn: dependOn, dependOnVal: $(this).data("depend-on-val") };
        }).toArray();
      }
      var filtering_select = $('<div class="input-append filtering-select"></div>')
      var input = this.input = $('<input type="text">')
        .val(value)
        .addClass("ra-filtering-select-input")
        .attr('style', select.attr('style'))
        .show()
        .autocomplete({
          delay: this.options.searchDelay,
          minLength: this.options.minLength,
          source: this._getSourceFunction(this.options.source),
          select: function(event, ui) {
            var option = $('<option></option>').attr('value', ui.item.id).attr('selected', 'selected').text(ui.item.value);
            select.html(option);
            select.trigger("change", ui.item.id);
            self._trigger("selected", event, {
              item: option
            });
            $(self.element.parents('.controls')[0]).find('.update').removeClass('disabled');
          },
          change: function(event, ui) {
            if (!ui.item) {
              var matcher = new RegExp("^" + $.ui.autocomplete.escapeRegex($(this).val()) + "$", "i"),
                  valid = false;
              select.children("option").each(function() {
                if ($(this).text().match(matcher)) {
                  this.selected = valid = true;
                  return false;
                }
              });
              if ((!valid || $(this).val() == '') && !select.data("editable")) {
                // remove invalid value, as it didn't match anything
                $(this).val(null);
                select.html($('<option value="" selected="selected"></option>'));
                input.data("ui-autocomplete").term = "";
                $(self.element.parents('.controls')[0]).find('.update').addClass('disabled');
                return false;
              }

            }
          }
        })
        .keyup(function() {
          /* Clear select options and trigger change if selected item is deleted */
          if ($(this).val().length == 0) {
            select.html($('<option value="" selected="selected"></option>'));
            select.trigger("change");
          }
        })

      if(select.attr('placeholder'))
        input.attr('placeholder', select.attr('placeholder'))

      input.data("ui-autocomplete")._renderItem = function(ul, item) {
        if(item.dependOn && item.dependOn != "" && String($("[name='" + item.dependOn + "']").val()) != String(item.dependOnVal)) {
          return $("<li></li>");
        } else {
          return $("<li></li>")
            .data("ui-autocomplete-item", item)
            .append( $( "<a class='ra-enum-option' data-depend-on='" + item.dependOn + "' data-depend-on-val='" + item.dependOnVal + "'></a>" ).html( item.label || item.id ) )
            .appendTo(ul);
        }
      };

      // replace with dropdown button once ready in twitter-bootstrap
      if(this.element.hasClass("ra-category")) {
        var button = this.button = $('<label href="#' + this.element.attr("name").replace(/\]/g, "").replace(/\[/g, "-") + '" data-toggle="modal" class="add-on ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only" title="Show All Items" role="button"><span class="ui-button-icon-primary ui-icon ui-icon-triangle-1-s"></span><span class="ui-button-text">&nbsp;</span></label>')
      } else {
        var button = this.button = $('<label class="add-on ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only" title="Show All Items" role="button"><span class="ui-button-icon-primary ui-icon ui-icon-triangle-1-s"></span><span class="ui-button-text">&nbsp;</span></label>')
        button.click(function() {
          // close if already visible
          if (input.autocomplete("widget").is(":visible")) {
            input.autocomplete("close");
            return;
          }

          // pass empty string as value to search for, displaying all results
          input.autocomplete("search", "");
          input.focus();
        });
      }

      filtering_select.append(input).append(button).insertAfter(select);


    },

    _getResultSet: function(request, data, xhr) {
      var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");

      return $.map(data, function(el, i) {
        // match regexp only for local requests, remote ones are already filtered, and label may not contain filtered term.
        if ((el.id || el.value) && (xhr || matcher.test(el.label))) {
          return {
            label: el.label ? el.label.replace(
              new RegExp(
                "(?![^&;]+;)(?!<[^<>]*)(" +
                $.ui.autocomplete.escapeRegex(request.term) +
                ")(?![^<>]*>)(?![^&;]+;)", "gi"
             ), "<strong>$1</strong>") : el.id,
            dependOnVal: el.dependOnVal,
            dependOn: el.dependOn,
            value: el.label || el.id,
            id: el.id || el.value
          };
        }
      });
    },

    _getSourceFunction: function(source) {

      var self = this,
          requestIndex = 0;

      if ($.isArray(source)) {

        return function(request, response) {
          response(self._getResultSet(request, source, false));
        };

      } else if (typeof source === "string") {

        return function(request, response) {

          if (this.xhr) {
            this.xhr.abort();
          }
          var dependOnVal = "";
          var wrap = $(this.element).closest("td").get(0) || $(this.element).parents(".controls").get(0) || $(this.element).parents(".ra-search-item").get(0);
          var $wrap = $(wrap);
          $wrap.css('padding-right', '26px');
          $wrap.find(".ra-loading").remove();
          $wrap.append("<span class='ra-loading' title='loading'><img src='/assets/rails_admin/loading.gif' style='width: 20px; margin-left:2px' /></span>");
          if ($wrap.find(".ra-enum").closest("td").find(".ra-enum").data("depend-on")) {
            var dependOnName = $(this.element).closest("td").find(".ra-enum").data("depend-on");
            if(dependOnName.match(/{index}/)) {
              var index = $wrap.find(".ra-enum").attr("name").match(/\[(\d+)\]/)[1];
              dependOnName = dependOnName.replace("{index}", index);
            }
            dependOnVal = $("[name='" + dependOnName + "']").val();
          }
          else if ($wrap.find(".ra-enum").data("depend-on")) {
            var dependOnName = $wrap.find(".ra-enum").data("depend-on");
            dependOnVal = $("[name='" + dependOnName + "']").val();
          }
          this.xhr = $.ajax({
            url: source,
            data: self.options.createQuery(request.term, dependOnVal, $(".s-object-id").val()),
            dataType: "json",
            autocompleteRequest: ++requestIndex,
            success: function(data, status) {
              var wrap = $(self.element).closest("td").get(0) || $(self.element).parents(".controls").get(0) || $(self.element).parents(".ra-search-item").get(0);
              $(wrap).find(".ra-loading").remove();
              if (this.autocompleteRequest === requestIndex) {
                response(self._getResultSet(request, data, true));
              }
            },
            error: function() {
              if (this.autocompleteRequest === requestIndex) {
                response([]);
              }
            }
          });
        };

      } else {

        return source;
      }
    },

    destroy: function() {
      this.input.remove();
      this.button.remove();
      this.element.show();
      $.Widget.prototype.destroy.call(this);
    }
  });
})(jQuery);
