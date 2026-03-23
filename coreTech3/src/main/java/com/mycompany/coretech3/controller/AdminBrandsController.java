package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.BrandsService;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("admin/brands")
@Produces(MediaType.APPLICATION_JSON)
public class AdminBrandsController {

    @Inject
    private BrandsService brandsService;

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response createBrand(String body) {
        System.out.println("=== ADMIN CREATE BRAND CALLED ===");
        try {
            JSONObject obj = new JSONObject(body);
            String name = obj.getString("name");
            String description = obj.getString("description");
            String logoUrl = obj.getString("logoUrl");

            JSONObject result = brandsService.createBrand(name, description, logoUrl);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "InvalidRequest");
            error.put("statusCode", 400);
            error.put("message", "Invalid request body: " + e.getMessage());
            return Response.status(400)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @PUT
    @Path("delete/{brandId}")
    public Response deleteBrand(@PathParam("brandId") int brandId) {
        System.out.println("=== ADMIN DELETE BRAND CALLED: " + brandId + " ===");
        JSONObject result = brandsService.deleteBrand(brandId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}
