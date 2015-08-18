utilMapProperty = require('./map-properties')
utilSchemas = require('./schemas')
camelCase = require('camel-case')
mapRequestResponse = require('./map-request-response')
_ = require('lodash')

util = {}

util.parseResource = (resource, options, schemas, customAdapter = null, parentUri = "", parentUriArgs = []) ->
  parsed = []
  
  resourceUri = parentUri + resource.relativeUri
  uriArgs = getUriParameter(resource, options.annotations.path, options.mapping)
  uriArgs = parentUriArgs.concat(uriArgs)
  
  if resource.methods
    for m in resource.methods
      methodDef = {}
      methodDef.uri = parentUri + resource.relativeUri
      methodDef.annotation = m.method.toUpperCase()
      methodDef.name = camelCase(m.method + ' ' + resource.displayName)
      methodDef.displayName = resource.displayName
      methodDef.args = uriArgs.concat(getQueryParams(m.queryParameters, options.annotations.query, options.mapping))
      methodDef.args = methodDef.args.concat(parseForm(m.body, options.annotations, options.mapping))
      request = utilSchemas.parseBodyJson(m.body, "#{methodDef.uri} body")
      responseBody = null
      bestResponse = getBestValidResponse(m.responses)
      if bestResponse
        responseBody = bestResponse.body
      respond = utilSchemas.parseBodyJson(responseBody, "#{methodDef.uri} response")
  
      if request.title
        methodDef.args = methodDef.args ? []
        classType = mapRequestResponse(request, schemas, options.mapping)
        methodDef.args.push {'kind': options.annotations.body, 'classType': classType, 'name': camelCase(request.title)}
  
      methodDef.request = request.title ? null
      responseType = mapRequestResponse(respond, schemas, options.mapping)
      methodDef.respondComment = respond.title
      if responseType
        methodDef.respond =  responseType
      else
        methodDef.respond =  "Response"
  
      #Sometimes is necessary to adapt the generic parser
      if customAdapter and typeof customAdapter is 'function'
        customAdapter(m, methodDef)
  
      parsed.push methodDef

  if resource.resources
    for innerResource in resource.resources
      parsed = parsed.concat(util.parseResource(innerResource, options, schemas, customAdapter, resourceUri, uriArgs))

  parsed


getUriParameter = (resource, annotation, mapping)->
  uriParameters = []
  for key of resource.uriParameters
    p = resource.uriParameters[key]
    uriParameters.push utilMapProperty.mapProperty(p, key, annotation, mapping).property
  uriParameters

getQueryParams = (queryParams, annotation, mapping)->
  params = []
  for key of queryParams
    p = queryParams[key]
    params.push utilMapProperty.mapProperty(p, key, annotation, mapping).property
  params

parseForm = (body, annotations, mapping) ->
  args = []
  form = if body then body["multipart/form-data"] or body["application/x-www-form-urlencoded"]

  if form
    if body["multipart/form-data"] isnt undefined
      annotation = annotations.multiPart
    else
      annotation = annotations.form
    data = form.formParameters or form.formParameters
    for key of data
      p = data[key]
      parsedProperty = utilMapProperty.mapProperty(p, key, annotation, mapping).property
      args.push parsedProperty
      if parsedProperty.classType is "InputStream"
        args.push {name: parsedProperty.name + "Data", classType: "FormDataContentDisposition", kind: annotation + "(\"#{parsedProperty.name}\")"}
  args

getBestValidResponse = (responses) ->
  response = responses["304"] ?
  response = responses["204"] ?
  response = responses["201"] ?
  response = responses["200"] ?
  response

module.exports = util.parseResource
