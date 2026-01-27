
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.BrandsService;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("brands")
@Produces(MediaType.APPLICATION_JSON)
public class BrandsController {
    
    @Inject
    private BrandsService brandsService;
    
    @GET
    public Response getAllBrands() {
        System.out.println("=== GET ALL BRANDS CALLED ===");
        JSONObject result = brandsService.getAllBrands();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
    
    @GET
    @Path("{brandId}")
    public Response getBrandById(@PathParam("brandId") int brandId) {
        System.out.println("=== GET BRAND BY ID CALLED: " + brandId + " ===");
        JSONObject result = brandsService.getBrandById(brandId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}
