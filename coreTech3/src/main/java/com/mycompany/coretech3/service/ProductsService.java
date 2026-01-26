package com.mycompany.coretech3.service;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.ParameterMode;
import javax.persistence.PersistenceContext;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;


@Stateless
public class ProductsService {
    
    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;
    
    
    public JSONObject getAllProducts() {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAllProducts");
            List<Object[]> results = spq.getResultList();
            
            JSONArray productsArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject product = new JSONObject();
                product.put("id", row[0]);
                product.put("name", row[1]);
                product.put("description", row[2]);
                product.put("price", row[3]);
                product.put("stock", row[4]);
                product.put("image_url", row[5]);
                product.put("category_id", row[6]);
                product.put("brand_id", row[7]);
                product.put("created_at", row[8]);
                product.put("category_name", row[9]);
                product.put("brand_name", row[10]);
                productsArray.put(product);
            }
            
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("products", productsArray);
            resp.put("count", productsArray.length());
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
    
    
    public JSONObject getProductById(int productId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getProductById");
            spq.registerStoredProcedureParameter("productIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("productIdIN", productId);
            
            List<Object[]> results = spq.getResultList();
            
            if (results == null || results.isEmpty()) {
                resp.put("status", "ProductNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Product with ID " + productId + " not found");
                return resp;
            }
            
            Object[] row = results.get(0);
            JSONObject product = new JSONObject();
            product.put("id", row[0]);
            product.put("name", row[1]);
            product.put("description", row[2]);
            product.put("price", row[3]);
            product.put("stock", row[4]);
            product.put("image_url", row[5]);
            product.put("category_id", row[6]);
            product.put("brand_id", row[7]);
            product.put("created_at", row[8]);
            product.put("category_name", row[9]);
            product.put("brand_name", row[10]);
            
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("product", product);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
}
