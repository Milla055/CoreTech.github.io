/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.ProductsService;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("products")
@Produces(MediaType.APPLICATION_JSON)
public class ProductsController {

    @Inject
    private ProductsService productsService;

    @GET
    public Response getAllProducts() {
        System.out.println("=== GET ALL PRODUCTS CALLED ===");
        JSONObject result = productsService.getAllProducts();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("{productId}")
    public Response getProductById(@PathParam("productId") int productId) {
        System.out.println("=== GET PRODUCT BY ID CALLED: " + productId + " ===");
        JSONObject result = productsService.getProductById(productId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("category/{categoryId}")
    public Response getProductsByCategoryId(@PathParam("categoryId") int categoryId) {
        System.out.println("=== GET PRODUCTS BY CATEGORY ID CALLED: " + categoryId + " ===");
        JSONObject result = productsService.getProductsByCategoryId(categoryId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("brand/{brandId}")
    public Response getProductsByBrandId(@PathParam("brandId") int brandId) {
        System.out.println("=== GET PRODUCTS BY BRAND ID CALLED: " + brandId + " ===");
        JSONObject result = productsService.getProductsByBrandId(brandId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    @GET
    @Path("{productId}/images/{imageIndex}")
    @Produces("image/png")
    public Response getProductImage(@PathParam("productId") int productId,
            @PathParam("imageIndex") int imageIndex) {
        System.out.println("=== GET PRODUCT IMAGE CALLED: Product " + productId + ", Image " + imageIndex + " ===");
        return productsService.getProductImage(productId, imageIndex);
    }
}
