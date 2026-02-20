/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;

import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class FavoritesService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;
    

    public JSONObject addToFavorites(int userId, int productId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("createFavorites");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("productIdIN", Integer.class, ParameterMode.IN);
            
            spq.setParameter("userIdIN", userId);
            spq.setParameter("productIdIN", productId);
            spq.execute();
            
            resp.put("status", "FavoriteAdded");
            resp.put("statusCode", 201);
            resp.put("message", "Product added to favorites");
            
        } catch (Exception e) {
            e.printStackTrace();
            // Check if it's a duplicate key error
            if (e.getMessage().contains("Duplicate") || e.getMessage().contains("unique")) {
                resp.put("status", "AlreadyInFavorites");
                resp.put("statusCode", 409);
                resp.put("message", "Product already in favorites");
            } else {
                resp.put("status", "DatabaseError");
                resp.put("statusCode", 500);
                resp.put("message", e.getMessage());
            }
        }
        return resp;
    }
    
    
    public JSONObject removeFromFavorites(int userId, int productId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("deleteFavorites");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("productIdIN", Integer.class, ParameterMode.IN);
            
            spq.setParameter("userIdIN", userId);
            spq.setParameter("productIdIN", productId);
            spq.execute();
            
            resp.put("status", "FavoriteRemoved");
            resp.put("statusCode", 200);
            resp.put("message", "Product removed from favorites");
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
    
    public JSONObject getMyFavorites(int userId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getFavoritesByUserId");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);
            
            List<Object[]> results = spq.getResultList();
            
            JSONArray favoritesArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject favorite = new JSONObject();
                favorite.put("favorite_id", row[0]);           // favorites.id
                favorite.put("user_id", row[1]);               // favorites.user_id
                favorite.put("product_id", row[2]);            // favorites.product_id
                favorite.put("created_at", row[3]);            // favorites.created_at
                favorite.put("username", row[4]);              // users.username
                favorite.put("product_name", row[5]);          // products.name
                favorite.put("product_price", row[6]);         // products.price
                favorite.put("category_name", row[7]);         // categories.name
                favorite.put("brand_name", row[8]);            // brands.name
                favoritesArray.put(favorite);
            }
            
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("favorites", favoritesArray);
            resp.put("count", favoritesArray.length());
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
}
