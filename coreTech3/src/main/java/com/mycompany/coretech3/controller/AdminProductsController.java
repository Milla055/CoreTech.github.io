/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.ProductsService;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.PUT;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("admin/products")
@Produces(MediaType.APPLICATION_JSON)
public class AdminProductsController {
    
    @Inject
    private ProductsService productsService;
    
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response createProduct(String body) {
        System.out.println("=== ADMIN CREATE PRODUCT CALLED ===");
        try {
            JSONObject obj = new JSONObject(body);
            int categoryId = obj.getInt("categoryId");
            int brandId = obj.getInt("brandId");
            String name = obj.getString("name");
            String description = obj.getString("description");
            double price = obj.getDouble("price");
            int stock = obj.getInt("stock");
            String imageUrl = obj.getString("imageUrl");
            
            JSONObject result = productsService.createProduct(
                categoryId, brandId, name, description, price, stock, imageUrl
            );
            
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
    @Path("{productId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response updateProduct(@PathParam("productId") int productId, String body) {
        System.out.println("=== ADMIN UPDATE PRODUCT CALLED: " + productId + " ===");
        try {
            JSONObject obj = new JSONObject(body);
            int categoryId = obj.getInt("categoryId");
            int brandId = obj.getInt("brandId");
            String name = obj.getString("name");
            String description = obj.getString("description");
            double price = obj.getDouble("price");
            int stock = obj.getInt("stock");
            String imageUrl = obj.getString("imageUrl");
            
            JSONObject result = productsService.updateProduct(
                productId, categoryId, brandId, name, description, price, stock, imageUrl
            );
            
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
    @Path("delete/{productId}")
    public Response deleteProduct(@PathParam("productId") int productId) {
        System.out.println("=== ADMIN DELETE PRODUCT CALLED: " + productId + " ===");
        JSONObject result = productsService.deleteProduct(productId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
    
}
