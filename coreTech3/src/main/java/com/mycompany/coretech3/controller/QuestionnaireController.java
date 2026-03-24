package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.QuestionnaireService;
import javax.annotation.security.PermitAll;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.OPTIONS;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.QueryParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;


@Path("questionnaire")
public class QuestionnaireController {

    @Inject
    private QuestionnaireService questionnaireService;

    /**
     * OPTIONS handler for CORS preflight requests
     */
    @OPTIONS
    @Path("{path : .*}")
    public Response handlePreflight() {
        return Response.ok()
                .header("Access-Control-Allow-Origin", "http://localhost:4200")
                .header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                .header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
                .header("Access-Control-Max-Age", "3600")
                .build();
    }


    @GET
    @Path("games")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getGames(@QueryParam("type") String gameType) {
        try {
            JSONObject result = questionnaireService.getGamesList(gameType);
            
            int statusCode = result.optInt("statusCode", 500);
            return Response.status(statusCode)
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 500);
            error.put("message", e.getMessage());
            return Response.status(500)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

   
    @POST
    @Path("recommend")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response recommendConfigurations(String body) {
        try {
            JSONObject requestData = new JSONObject(body);
            
            // Request paraméterek kinyerése
            Integer budgetMin = requestData.optInt("budgetMin", 0);
            Integer budgetMax = requestData.optInt("budgetMax", 0);
            String useCase = requestData.optString("useCase", "");
            String selectedGameIds = requestData.optString("selectedGameIds", null);
            
            // Validálás
            if (budgetMin == 0 || budgetMax == 0) {
                JSONObject error = new JSONObject();
                error.put("status", "ValidationError");
                error.put("statusCode", 400);
                error.put("message", "budgetMin and budgetMax are required");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }
            
            if (useCase == null || useCase.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "ValidationError");
                error.put("statusCode", 400);
                error.put("message", "useCase is required (gaming, video_editing, programming, all_purpose)");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }
            
            // Service hívás
            JSONObject result = questionnaireService.getRecommendedConfigurations(
                    budgetMin, 
                    budgetMax, 
                    useCase, 
                    selectedGameIds
            );
            
            int statusCode = result.optInt("statusCode", 500);
            return Response.status(statusCode)
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 500);
            error.put("message", e.getMessage());
            return Response.status(500)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    
    @GET
    @Path("configurations/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getConfigurationDetails(@PathParam("id") Long configId) {
        try {
            JSONObject result = questionnaireService.getConfigurationDetails(configId);
            
            int statusCode = result.optInt("statusCode", 500);
            return Response.status(statusCode)
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 500);
            error.put("message", e.getMessage());
            return Response.status(500)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

  
    @GET
    @Path("configurations/{id}/products")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getConfigurationProducts(@PathParam("id") Long configId) {
        try {
            JSONObject result = questionnaireService.getConfigurationProducts(configId);
            
            int statusCode = result.optInt("statusCode", 500);
            return Response.status(statusCode)
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 500);
            error.put("message", e.getMessage());
            return Response.status(500)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
}