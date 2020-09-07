treeSelect = {
  init : function() {
    this.initStatus();
    this.bindingEvent();
  },

  initStatus : function() {
    this.appendHTML();
    this.appendCSS();
  },

  bindingEvent : function() {
    $("body").on("click", ".ts-wrap .ts-node", this.selectedNode);
    $("body").on("click", ".ts-wrap .ts-button", this.openList);
//    $("body").on("click", ".ts-search .ra-search", this.serachKeyWord);
  },

  template : function() {
    return '<div class="ts-wrap"> \
              <select style="display:none;" name="{name}"></select> \
              <div class="ts-box"> \
                <input class="ts-input" type="text" placeholder="选择" /> \
                <label class="ts-button ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only" role="button"> \
                  <span class="ui-button-icon-primary ui-icon ui-icon-triangle-1-s"></span> \
                  <span class="ui-button-text">&nbsp;</span> \
                </label> \
              </div> \
              <div class="ts-list" style="display:none;"> \
                {nodes} \
              </div> \
            </div>'
  },
  openList : function() {
    $(this).parents(".ts-wrap").find(".ts-list").show();
  },
  genNodes : function(nodes, level) {
    var childrenNodeHTML = "";
    var len = nodes.length;
    for(var nodeIndex = 0; nodeIndex < len; nodeIndex++) {
      var node = nodes[nodeIndex];
      if(node.children) {
        childrenNodeHTML += '<div class="ts-nodes"><div class="ts-node" data-value="{value}"><b style="padding-left:{level}px">{nodeName}</b></div>{children}</div>'.replace(/{nodeName}/, node.name)
                                                                                                                        .replace(/{value}/, node.value).replace(/{level}/, level*10)
                                                                                                                        .replace(/{children}/, treeSelect.genNodes(node.children, level + 1));
      } else {
        childrenNodeHTML += '<div class="ts-node" data-value="{value}"><b style="padding-left:{level}px">{nodeName}</b></div>'.replace(/{nodeName}/, node.name)
                                                                                        .replace(/{value}/, node.value).replace(/{level}/, level*10);
      }
    }
    return '<div class="ts-nodes">' + childrenNodeHTML + '</div>';
  },

  appendHTML : function() {
    $(".ts-element").each(function(i, e) {
      var nodesHTML = treeSelect.genNodes($(e).data("nodes"), 0);
      var html = treeSelect.template().replace(/{nodes}/, nodesHTML)
                                      .replace(/{name}/, $(e).data("name"));
      $(e).html(html);
    });
  },

  appendCSS : function() {
    var style = "<style>.ra-item { font-size: 11px; } li.ra-item:nth-child(odd) { background-color: #eeeeee; } .ra-category-modal .ra-list li.ra-item.ra-selected { background: #00CAFC; color: #fff; } .ts-element .ts-list { top: 44px; width: auto; } .ts-element .ts-nodes { left: auto; } .ts-element .ts-node { font-size: 11px; margin: 0; padding: 5px; border-bottom: 1px solid #fff; } .ts-element .ts-node:hover { cursor: pointer; border-bottom: 1px solid #ddd; background: #eee; } .ts-search { display: none; } .ts-wrap .ts-list { max-width: 340px; } </style>";
    $("body div").first().before(style);
  },

  selectedNode : function() {
    var $wrap = $(this).parents(".ts-element");
    $wrap.find(".ts-input").val($(this).text());
    if($wrap.data("after-selected")) {
      eval($wrap.data("after-selected"))($wrap, $(this).data("value"));
    }
    $wrap.find(".ts-list").hide();
  },

  serachKeyWord : function() {
    searchValue = $(".ra-search").val();
    if(searchValue == ""){
      $(".ra-serach").focus();
      return;
    }
    alert(searchValue);
  }
}
