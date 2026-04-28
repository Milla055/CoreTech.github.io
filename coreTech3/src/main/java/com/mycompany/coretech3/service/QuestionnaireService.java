package com.mycompany.coretech3.service;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;


@Stateless
public class QuestionnaireService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    /**
     * Játékok listázása - opcionális szűrés típus szerint
     */
    public JSONObject getGamesList(String gameType) {
        JSONObject resp = new JSONObject();
        
        try {
            List<Object[]> results;
            
            // Ha gameType null vagy üres, JPQL query-t használunk
            if (gameType == null || gameType.trim().isEmpty()) {
                results = em.createNativeQuery(
                    "SELECT id, name, game_type, requirement_level, description " +
                    "FROM games " +
                    "WHERE is_deleted IS NULL " +
                    "ORDER BY requirement_level ASC, name ASC"
                ).getResultList();
            } else {
                // Ha van gameType, stored procedure-t használunk
                StoredProcedureQuery query = em.createStoredProcedureQuery("getGamesList");
                query.registerStoredProcedureParameter("gameTypeFilter", String.class, ParameterMode.IN);
                query.setParameter("gameTypeFilter", gameType);
                query.execute();
                results = query.getResultList();
            }
            
            JSONArray gamesArray = new JSONArray();
            
            for (Object[] row : results) {
                JSONObject game = new JSONObject();
                game.put("id", row[0]);
                game.put("name", row[1]);
                game.put("gameType", row[2]);
                game.put("requirementLevel", row[3]);
                game.put("description", row[4]);
                gamesArray.put(game);
            }
            
            resp.put("games", gamesArray);
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        
        return resp;
    }

    
    public JSONObject getRecommendedConfigurations(
            Integer budgetMin, 
            Integer budgetMax, 
            String useCase, 
            String selectedGameIds) {
        
        JSONObject resp = new JSONObject();
        
        try {
            StoredProcedureQuery query = em.createStoredProcedureQuery("getRecommendedConfigurations");
            
            query.registerStoredProcedureParameter("budgetMinIN", Integer.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("budgetMaxIN", Integer.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("useCaseIN", String.class, ParameterMode.IN);
            query.registerStoredProcedureParameter("selectedGameIdsIN", String.class, ParameterMode.IN);
            
            query.setParameter("budgetMinIN", budgetMin);
            query.setParameter("budgetMaxIN", budgetMax);
            query.setParameter("useCaseIN", useCase);
            // Üres string-et küldünk ha null (procedure ezt kezeli)
            query.setParameter("selectedGameIdsIN", (selectedGameIds != null && !selectedGameIds.trim().isEmpty()) ? selectedGameIds : "");
            
            query.execute();
            List<Object[]> results = query.getResultList();
            
            JSONArray configurationsArray = new JSONArray();
            
            for (Object[] row : results) {
                JSONObject config = new JSONObject();
                
                // Alap konfiguráció adatok
                config.put("id", row[0]);
                config.put("name", row[1]);
                config.put("description", row[2]);
                config.put("budgetMin", row[3]);
                config.put("budgetMax", row[4]);
                config.put("useCase", row[5]);
                config.put("gameTypes", row[6]);
                config.put("requirementLevel", row[7]);
                config.put("totalPrice", row[8]);
                config.put("isFeatured", row[9]);
                
                // ÚJ MEZŐK - products táblából JOIN-olva
                config.put("productId", row[10]);      // pc.product_id
                config.put("stock", row[11]);          // p.stock
                config.put("imageUrl", row[12]);       // p.image_url
                config.put("price", row[13]);          // p.price (aktuális ár)
                
                // PROPERTIES JSON - pre-built PC specifikációk
                String propertiesJson = (String) row[14];  // p.properties
                if (propertiesJson != null && !propertiesJson.trim().isEmpty()) {
                    // Parse-oljuk a JSON string-et JSONObject-té
                    try {
                        JSONObject properties = new JSONObject(propertiesJson);
                        config.put("properties", properties);
                    } catch (Exception e) {
                        // Ha nem valid JSON, akkor string-ként adjuk vissza
                        config.put("properties", propertiesJson);
                    }
                } else {
                    config.put("properties", JSONObject.NULL);
                }
                
                configurationsArray.put(config);
            }
            
            resp.put("configurations", configurationsArray);
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        
        return resp;
    }

    
    public JSONObject getConfigurationDetails(Long configId) {
        JSONObject resp = new JSONObject();
        
        try {
            StoredProcedureQuery query = em.createStoredProcedureQuery("getConfigurationDetails");
            
            query.registerStoredProcedureParameter("configIdIN", Long.class, ParameterMode.IN);
            query.setParameter("configIdIN", configId);
            
            query.execute();
            List<Object[]> results = query.getResultList();
            
            if (results.isEmpty()) {
                resp.put("status", "ConfigurationNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Configuration not found");
                return resp;
            }
            
            Object[] row = results.get(0);
            JSONObject config = new JSONObject();
            
            // Alap konfiguráció adatok
            config.put("id", row[0]);
            config.put("name", row[1]);
            config.put("description", row[2]);
            config.put("budgetMin", row[3]);
            config.put("budgetMax", row[4]);
            config.put("useCase", row[5]);
            config.put("gameTypes", row[6]);
            config.put("requirementLevel", row[7]);
            config.put("totalPrice", row[8]);
            config.put("isFeatured", row[9]);
            config.put("createdAt", row[10]);
            
            // ÚJ MEZŐK - products táblából JOIN-olva
            config.put("productId", row[11]);      // pc.product_id
            config.put("stock", row[12]);          // p.stock
            config.put("imageUrl", row[13]);       // p.image_url
            config.put("price", row[14]);          // p.price
            
            // PROPERTIES JSON - pre-built PC specifikációk
            String propertiesJson = (String) row[15];  // p.properties
            if (propertiesJson != null && !propertiesJson.trim().isEmpty()) {
                try {
                    JSONObject properties = new JSONObject(propertiesJson);
                    config.put("properties", properties);
                } catch (Exception e) {
                    config.put("properties", propertiesJson);
                }
            } else {
                config.put("properties", JSONObject.NULL);
            }
            
            resp.put("configuration", config);
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        
        return resp;
    }

    
    public JSONObject getConfigurationProducts(Long configId) {
        JSONObject resp = new JSONObject();
        
        try {
            // Ellenőrizzük hogy létezik-e még a stored procedure
            try {
                StoredProcedureQuery query = em.createStoredProcedureQuery("getConfigurationProducts");
                query.registerStoredProcedureParameter("configIdIN", Long.class, ParameterMode.IN);
                query.setParameter("configIdIN", configId);
                query.execute();
                
                List<Object[]> results = query.getResultList();
                JSONArray productsArray = new JSONArray();
                
                for (Object[] row : results) {
                    JSONObject product = new JSONObject();
                    product.put("configProductId", row[0]);
                    product.put("componentType", row[1]);
                    product.put("quantity", row[2]);
                    product.put("isRequired", row[3]);
                    product.put("productId", row[4]);
                    product.put("productName", row[5]);
                    product.put("productDescription", row[6]);
                    product.put("price", row[7]);
                    product.put("stock", row[8]);
                    product.put("imageUrl", row[9]);
                    product.put("categoryName", row[10]);
                    product.put("brandName", row[11]);
                    product.put("subtotal", row[12]);
                    product.put("inStock", row[13]);
                    productsArray.put(product);
                }
                
                resp.put("products", productsArray);
                resp.put("status", "Success");
                resp.put("statusCode", 200);
                
            } catch (Exception procError) {
                // Ha a stored procedure nem létezik, üres listát adunk vissza
                resp.put("products", new JSONArray());
                resp.put("status", "Success");
                resp.put("statusCode", 200);
                resp.put("message", "Configuration products are stored in properties JSON");
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