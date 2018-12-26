'use strict'

var AWS = require('aws-sdk');
var codepipeline = new AWS.CodePipeline();

function exists(pipelines, pipeline) {
	return pipelines.pipelines.find(function(p) { return p.name === pipeline});
}

function clone(prNum, pipeline, callback){
	codepipeline.getPipeline({name:process.env.PIPELINE_TEMPLATE}, function (err, data) {
		if (err) {
			callback(err)
		} else {
			console.log(JSON.stringify(data));
			
			var oauth_token = process.env.GITHUB_OAUTH_TOKEN;
			if (!oauth_token) {
				callback(new Error('Missing oAuthToken'));
				return;
			}
			
			var pipelineConfig = {
				name: pipeline,
				roleArn: data.pipeline.roleArn,
				artifactStore: data.pipeline.artifactStore,
				stages: data.pipeline.stages
			}
			
			pipelineConfig.stages[0].actions[0].configuration["OAuthToken"] = oauth_token
			pipelineConfig.stages[0].actions[0].configuration["Branch"] = "pull/" + prNum + "/head"
			
			codepipeline.createPipeline(data, function(err, data){
				if (err) {
					callback(err)
				} else {
					callback(null, {operation:'create', result:'success'});
				}
			});
		}
	})
}

function destroy(pipeline){}

exports.handler = function(event, context, callback) {
	var response;
	
	if (event.header['X-GitHub-Event'] === 'pull_request'){
		var pr = event.body.pull_request;
		var prNum = pr.number;
		var pipeline = 'pr-'+prNum;
		
		codepipeline.listPipelines({}, function(err, pipelines) {
			console.log("Pipelines "+JSON.stringify(pipelines));
			if (err) {
				callback(err)
			} else {
				if (pr.state === 'open' && !exists(pipelines, pipeline)) {
					clone(prNum, pipeline, callback);
				} else if (pr.state === 'closed' && exists(pipelines, pipeline)) {
					destroy(pipeline, callback);
				} else {
					callback(null,{operation: 'no-op',result:'success'})
				}
			}
		})
		
	} else {
		callback(new Error("Missing required pull request header"));
	}
}