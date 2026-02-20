
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
public class CategoriesService {
    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;
    

    public JSONObject getAllCategories() {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAllCategories");
            List<Object[]> results = spq.getResultList();
            
            JSONArray categoriesArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject category = new JSONObject();
                category.put("id", row[0]);
                category.put("name", row[1]);
                category.put("description", row[2]);
                category.put("created_at", row[3]);
                categoriesArray.put(category);
            }
            
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("categories", categoriesArray);
            resp.put("count", categoriesArray.length());
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
    
    public JSONObject getCategoryById(int categoryId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getCategoryById");
            spq.registerStoredProcedureParameter("categoryIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("categoryIdIN", categoryId);
            
            List<Object[]> results = spq.getResultList();
            
            if (results == null || results.isEmpty()) {
                resp.put("status", "CategoryNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Category with ID " + categoryId + " not found");
                return resp;
            }
            
            Object[] row = results.get(0);
            JSONObject category = new JSONObject();
            category.put("id", row[0]);
            category.put("name", row[1]);
            category.put("description", row[2]);
            category.put("created_at", row[3]);
            
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("category", category);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
}

