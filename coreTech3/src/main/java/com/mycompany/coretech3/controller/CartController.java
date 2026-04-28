/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.security.JwtUtil;
import com.mycompany.coretech3.service.CartService;
import io.jsonwebtoken.Claims;
import java.util.List;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.persistence.ParameterMode;
import javax.persistence.PersistenceContext;
import javax.persistence.StoredProcedureQuery;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONArray;
import org.json.JSONObject;

@Path("cart")
@Produces(MediaType.APPLICATION_JSON)
public class CartController {

    @Inject
    private CartService cartService;
    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU") 
    private EntityManager em;

    // ========== ADD TO CART ==========
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response addToCart(@HeaderParam("Authorization") String authHeader, String body) {
        System.out.println("=== ADD TO CART CALLED ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Parse request body
            JSONObject obj = new JSONObject(body);
            int productId = obj.getInt("productId");
            int quantity = obj.getInt("quantity");

            // Validate quantity
            if (quantity <= 0) {
                JSONObject error = new JSONObject();
                error.put("status", "InvalidQuantity");
                error.put("statusCode", 400);
                error.put("message", "Quantity must be greater than 0");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            JSONObject result = cartService.addToCart(userId, productId, quantity);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 400);
            error.put("message", "Invalid request: " + e.getMessage());
            return Response.status(400)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @PUT
    public Response clearCart(@HeaderParam("Authorization") String authHeader) {
        System.out.println("=== CLEAR CART CALLED ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            JSONObject result = cartService.clearCart(userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
    // ========== DELETE CART ITEM ==========
@DELETE
@Path("{cartItemId}")
public Response deleteCartItem(@HeaderParam("Authorization") String authHeader,
                                @PathParam("cartItemId") int cartItemId) {
    System.out.println("=== DELETE CART ITEM CALLED: " + cartItemId + " ===");
    try {
        // Validate JWT (user must be logged in)
        String token = authHeader.substring(7);
        JwtUtil.validate(token);
        
        JSONObject result = cartService.deleteCartItem(cartItemId);
        
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
                
    } catch (Exception e) {
        e.printStackTrace();
        JSONObject error = new JSONObject();
        error.put("status", "Unauthorized");
        error.put("statusCode", 401);
        error.put("message", "Invalid token");
        return Response.status(401)
                .entity(error.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}
@PUT
@Path("{cartItemId}")
@Consumes(MediaType.APPLICATION_JSON)
public Response updateCartItemQuantity(@HeaderParam("Authorization") String authHeader,
                                       @PathParam("cartItemId") int cartItemId,
                                       String body) {
    System.out.println("=== UPDATE CART ITEM QUANTITY CALLED: " + cartItemId + " ===");
    try {
        // Validate JWT (user must be logged in)
        String token = authHeader.substring(7);
        JwtUtil.validate(token);
        
        // Parse request body
        JSONObject obj = new JSONObject(body);
        int quantity = obj.getInt("quantity");
        
        JSONObject result = cartService.updateCartItemQuantity(cartItemId, quantity);
        
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
                
    } catch (Exception e) {
        e.printStackTrace();
        JSONObject error = new JSONObject();
        error.put("status", "Error");
        error.put("statusCode", 400);
        error.put("message", "Invalid request: " + e.getMessage());
        return Response.status(400)
                .entity(error.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
    
}
@GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response getCart(@HeaderParam("Authorization") String authHeader) {
        System.out.println("=== GET CART CALLED ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);
            
            System.out.println("Getting cart for userId: " + userId);

            // Call stored procedure
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getCartByUserId");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);

            List<Object[]> rows = spq.getResultList();
            JSONArray items = new JSONArray();

            for (Object[] row : rows) {
                JSONObject item = new JSONObject();
                item.put("cart_id", row[0]);
                item.put("user_id", row[1]);
                item.put("item_id", row[3]);
                item.put("product_id", row[4]);
                item.put("quantity", row[5]);
                item.put("product_name", row[6]);
                item.put("product_price", row[7]);
                item.put("product_p_price", row[8]);
                item.put("product_image_url", row[9]);
                item.put("product_stock", row[10]);
                item.put("category_name", row[11]);
                item.put("brand_name", row[12]);
                item.put("line_total", row[13]);
                items.put(item);
            }

            JSONObject response = new JSONObject();
            response.put("status", "Success");
            response.put("statusCode", 200);
            response.put("items", items);
            response.put("count", items.length());

            System.out.println("✅ Cart retrieved: " + items.length() + " items");
            return Response.status(200)
                    .entity(response.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 500);
            error.put("message", "Failed to get cart: " + e.getMessage());
            return Response.status(500)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

}
