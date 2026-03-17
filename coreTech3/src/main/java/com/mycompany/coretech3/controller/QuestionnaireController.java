package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.QuestionnaireService;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.QueryParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

/**
 * QuestionnaireController - PC konfigurátor kérdőív REST API endpointok
 * 
 * Endpointok:
 * - GET  /api/questionnaire/games - játékok listája (opcionális type filter)
 * - POST /api/questionnaire/recommend - ajánlott konfigurációk
 * - GET  /api/configurations/{id} - konfiguráció részletei
 * - GET  /api/configurations/{id}/products - konfiguráció termékei
 */
@Path("questionnaire")
public class QuestionnaireController {

    @Inject
    private QuestionnaireService questionnaireService;

    @GET
    @Path("games")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getGames(@QueryParam("type") String gameType) {
        try {
            JSONObject result = questionnaireService.getGamesList(gameType);
            
            return Response.status(result.getInt("statusCode"))
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
            JSONObject obj = new JSONObject(body);
            
            // Request paraméterek kinyerése
            Integer budgetMin = obj.getInt("budgetMin");
            Integer budgetMax = obj.getInt("budgetMax");
            String useCase = obj.getString("useCase");
            String selectedGameIds = obj.optString("selectedGameIds", null); // opcionális
            
            // Validálás
            if (budgetMin == null || budgetMax == null) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "budgetMin and budgetMax are required");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }
            
            if (useCase == null || useCase.trim().isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
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
            
            return Response.status(result.getInt("statusCode"))
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
            
            return Response.status(result.getInt("statusCode"))
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
            
            return Response.status(result.getInt("statusCode"))
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
