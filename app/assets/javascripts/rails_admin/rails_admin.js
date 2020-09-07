//=  require 'jquery'
//=  require 'jquery_ujs'
//=  require 'rails_admin/jquery.remotipart.fixed'
//=  require 'jquery-ui'
//=  require 'rails_admin/jquery.ui.datepicker-zh-CN'
//=  require 'rails_admin/jquery.ui.timepicker'
//=  require 'rails_admin/ra.datetimepicker'
//=  require 'rails_admin/jquery.colorpicker'
//=  require 'rails_admin/ra.filter-box'
//=  require 'rails_admin/ra.filtering-multiselect'
//=  require 'rails_admin/ra.filtering-select'
//=  require 'rails_admin/ra.remote-form'
//=  require 'jquery_nested_form'
//=  require 'rails_admin/ra.nested-form-hooks'
//=  require 'rails_admin/ra.i18n'
//=  require 'rails_admin/bootstrap/bootstrap'
//=  require 'rails_admin/ra.widgets'
//=  require 'rails_admin/ui'
//=  require 'rails_admin/custom/ui'
//=  require 'rails_admin/jquery.treeSelect.js'
//=  require 'rails_admin/jquery.treegrid.js'
//=  require 'rails_admin/jquery.tokeninput.js'
//=  require 'rails_admin/jquery.ui.dialog.js'
//=  require 'rails_admin/lazysizes.min.js'

admin = {};

admin.global = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
  },

  bindingEvent : function() {
    $(".ra-print-btn").click(this.print);
  },

  print : function() {
    $("body").append("<iframe src='" + $(this).attr("href") + "' style='display:none;' />")
    return false;
  }
}

admin.indexPage = {
  init : function() {
    this.initStatus();
    if($("#ra-index-page").get(0)) {
      this.bindingEvent();
    }
  },

  initStatus : function() {
    if($(".tree_index").get(0)){
      $('.tree_index').treegrid()
    }
  },

  bindingEvent : function() {
    $(".ra-bulk-edit .ra-approval").click(this.bulkEditApproval);
    $(".ra-bulk-edit .ra-disapproval").click(this.bulkEditDisapproval);
  },

  bulkEditApproval : function() {
    $('#bulk_action').val("bulk_edit");
    $('#bulk_action_type').val($(this).data("param"));
    $('#bulk_form').submit();
    return false;
  },
  bulkEditDisapproval : function() {
    $('#bulk_action').val("bulk_edit");
    $('#bulk_action_type').val($(this).data("param"));
    $('#bulk_form').submit();
    return false;
  }
}

admin.reportPage = {
  init : function() {
    if($("#ra-report-page").get(0)) {
      this.initStatus();
      this.bindingEvent();
    }
  },

  initStatus : function() {
  },

  bindingEvent : function() {
    $(".ra-report-export .ra-link").click(this.exportReport);
  },

  exportReport : function() {
    location.href = $(this).attr("href") + "?" + $(".ra-filter-wrap").parents("form").serialize();
    return false;
  }
}

admin.printPage = {
  init : function() {
    if($("#ra-print-page").get(0)) {
      this.initStatus();
      this.bindingEvent();
    }
  },

  initStatus : function() {
    this.initNavs();
    window.print();
  },

  bindingEvent : function() {
  },

  initNavs : function() {
    /*var navs = $(".nav-tabs");
    $(".nav-tabs li").each(function(i, nav){
      var $newTabs = $(nav).parents(".nav-tabs").clone();
      var $newLi = $newTabs.find("li").eq(i).addClass("active");
      $newTabs.empty().append($newLi);
      $("#my-form").append($newTabs);
      $("#my-form").append($($newLi.find("a").attr("href")));
    });
    navs.hide();*/
  }
}

admin.map = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
    $(".cms-map").each(function(i, mapDom){
      var $wrap = $(mapDom).parents(".cms-map-wrap");
      var lat;
      var lng;
      if ($wrap.find(".cms-lat-input").val() == null || $wrap.find(".cms-lat-input").val() == 0 || $wrap.find(".cms-lng-input").val() == null || $wrap.find(".cms-lng-input").val() == 0) {
        lat = parseFloat($wrap.data("default-lat"));
        lng = parseFloat($wrap.data("default-lng"));
      } else {
        lat = parseFloat($wrap.find(".cms-lat-input").val());
        lng = parseFloat($wrap.find(".cms-lng-input").val());
      }
      var point = new BMap.Point(lng, lat);
      var marker = new BMap.Marker(point);
      var map = new BMap.Map(mapDom);
      map.centerAndZoom(point, 16);
      map.addOverlay(marker);
      map.addControl(new BMap.NavigationControl());
      marker.enableDragging();
      marker.addEventListener("dragend", function(e){
        var $_wrap = $(e.currentTarget.map.ja).parents(".cms-map-wrap");
        $_wrap.find(".cms-lat-input").val(e.point.lat);
        $_wrap.find(".cms-lng-input").val(e.point.lng);
      });
    });
  },

  bindingEvent : function() {
  }
}

admin.tableEdit = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
    this.makeItemSortable();
  },

  bindingEvent : function() {
    $(".ra-table-edit-wrap .ra-new-btn").click(this.addRow);
    $(".ra-table-edit-wrap").on("click", ".ra-delete-link", admin.tableEdit.deleteRow);
  },

  makeItemSortable : function() {
    $(".ra-table-edit-wrap").each(function(i, wrap) {
      if($(wrap).find(".ra-sort").get(0)) {
        $(wrap).sortable({
          items : ".ra-row",
          stop : function(event, ui) {
            var $wrap = ui.item.parents(".ra-table-edit-wrap");
            $wrap.find(".ra-row").each(function(rowIndex, row) {
              $(row).find(".ra-input-sort").val(rowIndex);
            });
          }
        });
      }
    });
  },

  addRow : function() {
    var $wrap = $(this).parents(".ra-table-edit-wrap");
    var rowHtml = $(".ra-table-edit-template[data-type='" + $(this).data("type") + "'] tbody").html().replace(/{index}/g, Date.now());
    $wrap.find(".ra-table tbody").append(rowHtml);
    $wrap.find(".ra-table tbody input").attr("disabled", null);
    $wrap.find(".ra-table tbody .ra-row:last").find(".filtering-select").remove();
    $(document).trigger("rails_admin.dom_ready");
    return false;
  },

  deleteRow : function() {
    var row = $(this).parents(".ra-row");
    if(row.find(".ra-input-destroy").get(0)) {
      row.find(".ra-input-destroy").val(1);
      row.hide();
    }else{
      row.remove();
    }
    return false;
  }
}

admin.enumeration = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
    this.dependOn();
  },

  bindingEvent : function() {
    $(".ra-enum").change(this.filterOutOptions);
    $("body").on("change", ".ra-enum.ra-autofill", this.fetchAndSyncData);
    $("body").on("click", ".ra-category-modal .ra-item", this.highLightItem);
    $("body").on("dblclick", ".ra-category-modal .ra-item", this.selectItem);
    $("body").on("click", ".ra-category-modal .ra-ok", this.updateSelectBoxValByCategoryMode);
    $(".enum_type .ra-filtering-select-input").keyup(this.updateSelectBoxVal);
  },

  dependOn : function() {
    $(".ra-enum").each(function(i, select) {
      var dependOnInputName = $(select).data("depend-on");
      if(dependOnInputName && dependOnInputName != "") {
        var $dependOnInput = $("[name='" + dependOnInputName + "']");
        $dependOnInput.change(function() {
          var $select = $(".ra-enum[data-depend-on='" + $(this).attr("name") + "']");
          admin.enumeration.toggle($(this), $select);
        });
        admin.enumeration.toggle($dependOnInput, $(select));
      }
    });
  },

  toggle : function($dependedOnSelect, $select) {
    var isShow = $dependedOnSelect.val() && $dependedOnSelect.val() != "";
    var isDependedOnSelectExit = $dependedOnSelect.get(0);
    var isDependedOnSelectNotInTableEdit = !$dependedOnSelect.parents(".ra-table-edit-wrap, .ra-table-edit-template").get(0);
    var isSelectInTableEdit = $select.parents(".ra-table-edit-template").get(0);
    if(isDependedOnSelectExit && isDependedOnSelectNotInTableEdit && isSelectInTableEdit) {
      var type = $select.parents(".ra-table-edit-template").data("type");
      $(".ra-table-edit-wrap[data-type='" + type + "']").toggle(isShow);
    }
  },

  fetchAndSyncData : function() {
    var _this = this;
    var data = {};
    $(".s-auto-fill-depend-on-data").each(function(i, e){
      data[$(e).find("label.control-label").attr("for")] = $(e).find("select option:selected").val();
    });
    data['key'] = $(this).data("autofill-key");
    data['value'] = $(this).val();

    if(data['value'] == "") {
      return false;
    }
    $.ajax({
      type: 'GET',
      data: data,
      url: "/admin/autofill",
      dataType: 'json',
      success: function(data) {
        admin.enumeration.syncData($(_this), data);
      }
    });
  },

  syncData : function($wrap, data) {
    $($wrap.data("autofill-attrs")).each(function(i, k_v) {
      if(k_v[1].match(/{index}/)) {
        // For table_edit
        var index = $wrap.attr("name").match(/[(\d+)]/)[0];
        k_v[1] = k_v[1].replace("{index}", index);
      }
      var $input = $("[name='" + k_v[1] + "']");
      if($input.hasClass("ra-enum")) {
        var d = data[k_v[0]]; //{ :supplier_id => [Supplier.last.id, Supplier.last.name] }
        if(d != undefined) {
          $input.val(d[0]);
          $input.parents(".controls").find(".ra-filtering-select-input").val(d[1]);
          if($input.val() != d[0]) {
            $input.find("option").last().val(d[0]);
            $input.find("option").last().text(d[1]);
            $input.find("option").last().attr('selected','selected');
          }
        }
      } else {
        $input.val(data[k_v[0]]);
        $input.text(data[k_v[0]]);
      }
    });
  },

  updateSelectBoxVal : function() {
    var $select = $(this).parents(".controls").find(".ra-enum");
    if($select.data("editable")) {
      $select.html('<option value="' + $(this).val() + '" selected="selected"></option>');
      return false;
    }
  },

  reloadCategoryResult : function($treeSelect, val) {
    $.ajax({
      type: 'GET',
      url: "/admin/enum_category",
      data: {
        key : $treeSelect.parents(".ra-category-modal").data("key"),
        value : val
      },
      dataType: 'json',
      success: function(data) {
        var $wrap = $treeSelect.parents(".ra-category-modal");
        $wrap.find(".ra-list").empty();
        $(data).each(function(i, item) {
          $wrap.find(".ra-list").append("<li class='ra-item' data-value='{value}'>{name}</li>".replace(/{name}/, item.name).replace(/{value}/, item.id));
        });
      }
    });
  },

  highLightItem : function() {
    $(this).parents(".ra-category-modal").find(".ra-item").removeClass("ra-selected");
    $(this).addClass("ra-selected");
  },

  selectItem : function() {
    $(this).parents(".ra-category-modal").find(".ra-item").removeClass("ra-selected");
    $(this).addClass("ra-selected");
    $(this).parents("div.ra-category-modal").find(".ra-ok").click();
  },

  updateSelectBoxValByCategoryMode : function() {
    var data = {};
    var $selectedItem = $(this).parents(".ra-category-modal").find(".ra-item.ra-selected");
    if($(this).parents(".ra-row").get(0) == undefined) {
      if($(this).parents(".ra-search-item").get(0)) {
        $(this).parents(".ra-search-item").find("select.ra-enum").html('<option value="' + $selectedItem.data("value") + '" selected="selected"></option>');
        $(this).parents(".ra-search-item").find("input.ra-filtering-select-input").val($selectedItem.text());
      }
      else {
        $(this).parents("div.controls").find("select.ra-enum").html('<option value="' + $selectedItem.data("value") + '" selected="selected"></option>');
        $(this).parents("div.controls").find("input.ra-filtering-select-input").val($selectedItem.text());

        var _this = $(this).parents("div.controls").find(".ra-enum.ra-autofill")
        data['key'] = $(this).parents("div.controls").find(".ra-autofill").data("autofill-key");
        data['value'] = $(this).parents("div.controls").find(".ra-autofill").val();
      }
    }
    else {
      $(this).parents("td").find("select.ra-category").html('<option value="' + $selectedItem.data("value") + '" selected="selected"></option>');
      $(this).parents("td").find("select.ra-category").parent().find("input.ra-filtering-select-input").val($selectedItem.text());

      var _this = $(this).parents("td").find(".ra-enum.ra-autofill")
      data['key'] = $(this).parents("td").find(".ra-autofill").data("autofill-key");
      data['value'] = $(this).parents("td").find(".ra-autofill").val();
    }

    $(".s-auto-fill-depend-on-data").each(function(i, e){
      data[$(e).find("label.control-label").attr("for")] = $(e).find("select option:selected").val();
    });

    if(data['value'] == "") {
      return false;
    }

    $.ajax({
      type: 'GET',
      data: data,
      url: "/admin/autofill",
      dataType: 'json',
      success: function(data) {
        admin.enumeration.syncData($(_this), data);
      }
    });
  }
}

admin.monthPicker = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
    $('.s-month-picker').datepicker( {
        changeMonth: true,
        changeYear: true,
        showButtonPanel: true,
        dateFormat: 'yy-mm',
        beforeShow: function() {
          $("body").addClass("s-month-picker");
        },
        onClose: function(dateText, inst) {
          var month = $("#ui-datepicker-div .ui-datepicker-month :selected").val();
          var year = $("#ui-datepicker-div .ui-datepicker-year :selected").val();
          $(this).datepicker('setDate', new Date(year, month, 1));
          setTimeout(function() {
            $("body").removeClass("s-month-picker");
          }, 200)
        }
    });
  },

  bindingEvent : function() {
  }
}

admin.report = {
  init : function() {
    if($("#ra-report-table").get(0)){
      this.initStatus();
      this.bindingEvent();
    }
  },

  initStatus : function() {
  },

  bindingEvent : function() {
  }
}

admin.focusChangeVal = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
  },

  bindingEvent : function() {
    $("body").on("focus", "input[type='number']", this.focusChange);
    $("body").on("blur", "input[type='number']", this.blurChange);
  },

  focusChange :function() {
    if($(this).val() == 0) {
      $(this).val("");
    }
  },

  blurChange: function() {
    if($(this).val() == "") {
      $(this).val(0);
    }
  }
}

admin.multiSelect = {
  init : function() {
    if($(".ra-multi-select-wrap").get(0)){
      this.initStatus();
      this.bindingEvent();
    }
  },

  initStatus : function() {
  },

  bindingEvent : function() {
  },

  tokenInputOnAdd : function(item, model, field, fieldKey){
    var formItems = ".ra_" + field + "_wrap " + " .ra-hidden-form-items";
    var domItem = $(formItems).find(".ra-item-" + item.id).get(0);
    if( domItem != undefined ){
      var domDestroy = $(domItem).find(".ra-item-destroy").get(0);
      $(domItem).find(".ra-item-destroy").val(0);
    }else{
      $(formItems).append(
        "<div class='ra-item-" + item.id + "'>"
          + "<input class='ra-item-input' name='" + model + "[" + field + "_attributes][" + item.id + "][" + fieldKey + "]' value='" + item.id + "'/>" +
        "</div>"
      );
    }
  },

  tokenInputOnDelete : function(item, model, field, fieldKey){
    var formItems = ".ra_" + field + "_wrap " + " .ra-hidden-form-items ";
    var domDestroy = $(formItems + " .ra-item-" + item.id).find(".ra-item-destroy").get(0);
    if( domDestroy != undefined ){
      $(domDestroy).val("1");
    }else{
      $(formItems + " .ra-item-" + item.id).remove();
    }
  }
}

admin.userSelect = {
  init : function() {
    if($(".ra-user-select-wrap").get(0)){
      this.initStatus();
      this.bindingEvent();
    }
  },

  initStatus : function() {
  },

  bindingEvent : function() {
    $(".ra-user-select-wrap .ra-user-selector").click(this.openUserDialog);
    $(".ra-user-dialog .ra-dropdown-toggle").click(this.toggleDropdown);
    $(".ra-user-dialog .ra-select-dropdown li span").click(this.filteUsers);
    $(".ra-user-dialog .ra-all-selector").change(this.selectUsers);
    $(".ra-user-dialog").on("keyup", ".ra-search-toolbar .ra-search-input", this.searchUsers);
  },

  openUserDialog : function(){
    $("#" + $(this).data("field") + "_dialog").dialog("open");
  },

  initDialog : function(field){
    $("#" + field + "_dialog .ra-dropdown-input").val("");
    $("#" + field + "_dialog .ra-search-input").val("");
    $("#" + field + "_dialog .ra-select-dropdown").hide();
    $("#" + field + "_dialog input[type=checkbox]:checked").prop("checked", false);
  },

  toggleDropdown : function(){
    var width = parseInt($(this).width() + $(".ra-dropdown-input").width()) + 6;
    var field = $(this).data("field");
    $("#" + field + "_dialog .ra-select-dropdown").width(width).slideToggle();
    return false;
  },

  filteUsers : function(e){
    var fieldName = $(this).parent().data("field");
    var ra_users = "#" + fieldName + "_dialog .ra-users ";
    var spanDataId = $(this).data("id") + "";
    if(spanDataId.indexOf("-") > 0){
      $( ra_users + " .ra-user-wrap").each(function(i,v){
        $(v).data("id") == spanDataId ? $(v).show() : $(v).hide();
      });
    }else{
      if(spanDataId == "0") {
        $( ra_users + " .ra-user-wrap").show();
      }else{
        $( ra_users + " .ra-user-wrap").each(function(i,v){
          var dataId = $(v).data("id") + "";
          spanDataId == dataId || (dataId.substring(0, dataId.indexOf("-")) == spanDataId) ? $(v).show() : $(v).hide();
        });
      }
    }
    $("#" + fieldName + "_dialog .ra-dropdown-input").val($(this).text());
    $("#" + fieldName + "_dialog .ra-select-dropdown").hide();
    e.stopPropagation();
  },

  searchUsers : function(){
    var searchValue = $(this).val();
    if(searchValue == ""){
      return;
    }
    var fieldName = $(this).data("field");
    var ra_users = "#" + fieldName + "_dialog";
    $(ra_users + " .ra-user-wrap").each(function(i,v){
      var name = $(v).find(".ra-user-input").data("name");
      name.indexOf(searchValue) >= 0 ? $(v).show() : $(v).hide();
    });
  },

  selectUsers : function(){
    var ra_users = "#" + $(this).data("field") + "_dialog .ra-users ";
    var _this = this;
    $(ra_users + " .ra-user-wrap").each(function(i,v){
      if(v.style.display == "block"){
        $(v).find("input[type=checkbox]").prop("checked", _this.checked);
      }
    });
  },

  tokenInputOnAdd : function(item){
    var fieldDiv = ".ra_" + item.field + "_wrap ";
    var formField = fieldDiv + " .ra-form-field";
    var domItem = $(formField).find(".ra-user-" + item.id).get(0);
    if( domItem != undefined ){
      var domDestroy = $(domItem).find(".ra-user-destroy").get(0);
      $(domItem).find(".ra-user-destroy").val(0)
    }else{
      $(formField).append(
        "<div class='ra-user-" + item.id + "'>"
          + "<input class='ra-user-input' name='" + item.model + "[" + item.field + "_attributes][" + item.id + "][" + item.field_key + "]' value='" + item.id + "'/>" +
        "</div>"
      );
    }
  },

  tokenInputOnDelete : function(item){
    var fieldDiv = ".ra_" + item.field + "_wrap ";
    var formField = fieldDiv + " .ra-form-field ";
    var domDestroy = $(formField + " .ra-user-" + item.id).find(".ra-user-destroy").get(0);
    if( domDestroy != undefined ){
      $(domDestroy).val("1");
    }else{
      $(formField + " .ra-user-" + item.id).remove();
    }
  },

  dialogOnAdd : function(model,field,field_key){
    var $newSelectedUsers = $("#" + field + "_dialog .ra-users input[type=checkbox]:checked");
    if ($newSelectedUsers.length == 0) {
      $("#" + field + "_dialog" ).dialog( "close" );
      return;
    }
    var newSelectedUsers = [],formField = ".ra_" + field + "_wrap .ra-form-field ";
    $newSelectedUsers.each(function(i,v){
      var existUserWrap = $( formField + " .ra-user-" + v.value).get(0);
      if( existUserWrap == undefined){
        $(formField).append("<input class='ra-user-input' name='" + $(v).data("inputName") + "' value='" + v.value + "' />");
        $("#" + field + "_tokenInput").tokenInput("add", { id:v.value, name:$(v).data("name"), model:model, field:field, field_key:field_key});
      }else{
        var domDestroy = $(existUserWrap).find(".ra-user-destroy").get(0);
        if( domDestroy != undefined ){
          $("#" + field + "_tokenInput").tokenInput("add",{ id:v.value, name:$(v).data("name"), model:model, field:field, field_key:field_key});
          $(domDestroy).val(1);
        }
      }
    });

    $("#" + field + "_dialog").dialog( "close" );
  }

}

$(document).ready(function(){
  // Remove Modal box animation
  $.support.transition = null;
  admin.global.init();
  admin.indexPage.init();
  admin.printPage.init();
  admin.reportPage.init();
  admin.map.init();
  admin.tableEdit.init();
  treeSelect.init();
  admin.enumeration.init();
  admin.monthPicker.init();
  admin.report.init();
  admin.focusChangeVal.init();
  admin.userSelect.init();
  admin.multiSelect.init();
});
