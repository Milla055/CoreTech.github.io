
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.CategoriesService;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("categories")
@Produces(MediaType.APPLICATION_JSON)
public class CategoriesController {
     @Inject
    private CategoriesService categoriesService;
    
    @GET
    public Response getAllCategories() {
        System.out.println("=== GET ALL CATEGORIES CALLED ===");
        JSONObject result = categoriesService.getAllCategories();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
    
    @GET
    @Path("{categoryId}")
    public Response getCategoryById(@PathParam("categoryId") int categoryId) {
        System.out.println("=== GET CATEGORY BY ID CALLED: " + categoryId + " ===");
        JSONObject result = categoriesService.getCategoryById(categoryId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}

