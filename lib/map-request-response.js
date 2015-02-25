var Deref, pascalCase, util, _;

pascalCase = require('pascal-case');

_ = require('lodash');

Deref = require('deref');

util = {};

util.mapRequestResponse = function(scheme, schemas, mapping) {
  var dataRef, deref, normSchema, primitiveType, type;
  type = "";
  switch (scheme.type) {
    case "array":
      if (scheme.items) {
        type = "List<Maps>";
        if (scheme.items.$ref) {
          deref = Deref();
          normSchema = deref(scheme, schemas);
          dataRef = deref.util.findByRef(normSchema.items.$ref, deref.refs);
          if (dataRef && dataRef.title) {
            type = "List<" + (pascalCase(dataRef.title)) + ">";
          } else {
            type = "List";
          }
        } else if (scheme.items.title) {
          type = "List<" + (pascalCase(scheme.title)) + ">";
        } else if (scheme.items.type) {
          primitiveType = mapping[scheme.items.type];
          if (primitiveType) {
            type = "List<" + primitiveType + ">";
          }
        }
      } else {
        type = "List";
      }
      break;
    case "object":
      if (scheme.properties) {
        type = pascalCase(scheme.title);
      } else {
        type = "Map";
      }
      break;
    default:
      console.warn("-------WARNING the following scheme doesn't have type: -------");
      console.warn("" + (JSON.stringify(scheme)) + " ");
  }
  return type;
};

module.exports = util.mapRequestResponse;
