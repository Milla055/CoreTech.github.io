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
import org.json.JSONObject;

@Stateless
public class CartService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONObject addToCart(int userId, int productId, int quantity) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("addToCart");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("productIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("quantityIN", Integer.class, ParameterMode.IN);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("productIdIN", productId);
            spq.setParameter("quantityIN", quantity);
            spq.execute();

            resp.put("status", "AddedToCart");
            resp.put("statusCode", 200);
            resp.put("message", "Product added to cart");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject clearCart(int userId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("clearCart");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);
            spq.execute();

            resp.put("status", "CartCleared");
            resp.put("statusCode", 200);
            resp.put("message", "Cart cleared successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

public JSONObject deleteCartItem(int cartItemId) {
    JSONObject resp = new JSONObject();
    try {
        StoredProcedureQuery spq = em.createStoredProcedureQuery("removeFromCart");
        spq.registerStoredProcedureParameter("cartItemIdIN", Integer.class, ParameterMode.IN);
        spq.setParameter("cartItemIdIN", cartItemId);
        spq.execute();
        
        resp.put("status", "ItemRemoved");
        resp.put("statusCode", 200);
        resp.put("message", "Item removed from cart");
        
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
        resp.put("message", e.getMessage());
    }
    return resp;
}
// ========== UPDATE CART ITEM QUANTITY ==========
public JSONObject updateCartItemQuantity(int cartItemId, int quantity) {
    JSONObject resp = new JSONObject();
    try {
        StoredProcedureQuery spq = em.createStoredProcedureQuery("updateCartItemQuantity");
        spq.registerStoredProcedureParameter("cartItemIdIN", Integer.class, ParameterMode.IN);
        spq.registerStoredProcedureParameter("quantityIN", Integer.class, ParameterMode.IN);
        
        spq.setParameter("cartItemIdIN", cartItemId);
        spq.setParameter("quantityIN", quantity);
        spq.execute();
        
        if (quantity <= 0) {
            resp.put("status", "ItemRemoved");
            resp.put("statusCode", 200);
            resp.put("message", "Item removed from cart (quantity <= 0)");
        } else {
            resp.put("status", "QuantityUpdated");
            resp.put("statusCode", 200);
            resp.put("message", "Cart item quantity updated");
        }
        
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
        resp.put("message", e.getMessage());
    }
    return resp;
}
}
