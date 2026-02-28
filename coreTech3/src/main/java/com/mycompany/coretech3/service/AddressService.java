package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Addresses;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.List;

@Stateless
public class AddressService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    
    public JSONObject getUserAddresses(int userId) {
        JSONObject resp = new JSONObject();
        
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAddressesByUserId");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);
            
            List<Object[]> rows = spq.getResultList();
            JSONArray addresses = new JSONArray();
            
            for (Object[] row : rows) {
                JSONObject address = new JSONObject();
                address.put("id", row[0]);
                address.put("userId", row[1]);
                address.put("street", row[2]);
                address.put("city", row[3]);
                address.put("postalCode", row[4]);
                address.put("country", row[5]);
                address.put("isDefault", row[6]);
                address.put("createdAt", row[7]);
                
                addresses.put(address);
            }
            
            resp.put("addresses", addresses);
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Hiba történt a címek lekérdezése során: " + e.getMessage());
        }
        
        return resp;
    }

   
    public JSONObject createAddress(int userId, String street, String city, 
                                    String postalCode, String country, boolean isDefault) {
        JSONObject resp = new JSONObject();
        
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("createAddress");
            
            spq.registerStoredProcedureParameter("userIDIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("streetIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("cityIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("postalcodeIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("countryIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("isDefaultIN", Integer.class, ParameterMode.IN);
            
            spq.setParameter("userIDIN", userId);
            spq.setParameter("streetIN", street);
            spq.setParameter("cityIN", city);
            spq.setParameter("postalcodeIN", postalCode);
            spq.setParameter("countryIN", country);
            spq.setParameter("isDefaultIN", isDefault ? 1 : 0);
            
            spq.execute();
            
            resp.put("status", "AddressCreated");
            resp.put("statusCode", 201);
            resp.put("message", "Cím sikeresen létrehozva");
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Hiba történt a cím létrehozása során: " + e.getMessage());
        }
        
        return resp;
    }

    
    public JSONObject updateAddress(int addressId, int userId, String street, 
                                    String city, String postalCode, String country, 
                                    boolean isDefault) {
        JSONObject resp = new JSONObject();
        
        try {
            // Ellenőrizzük, hogy a cím ehhez a userhez tartozik-e
            Addresses address = em.find(Addresses.class, addressId);
            if (address == null) {
                resp.put("status", "AddressNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "A cím nem található");
                return resp;
            }
            
            if (address.getUserId().getId() != userId) {  
            resp.put("status", "Unauthorized");
            resp.put("statusCode", 403);
            resp.put("message", "Nincs jogosultságod ehhez a címhez");
            return resp;
        }
            
            StoredProcedureQuery spq = em.createStoredProcedureQuery("updateAddressById");
            
            spq.registerStoredProcedureParameter("addressIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("streetIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("cityIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("postalcodeIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("countryIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("isDefaultIN", Integer.class, ParameterMode.IN);
            
            spq.setParameter("addressIdIN", addressId);
            spq.setParameter("streetIN", street);
            spq.setParameter("cityIN", city);
            spq.setParameter("postalcodeIN", postalCode);
            spq.setParameter("countryIN", country);
            spq.setParameter("isDefaultIN", isDefault ? 1 : 0);
            
            spq.execute();
            
            resp.put("status", "AddressUpdated");
            resp.put("statusCode", 200);
            resp.put("message", "Cím sikeresen frissítve");
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Hiba történt a cím frissítése során: " + e.getMessage());
        }
        
        return resp;
    }

    public JSONObject deleteAddress(int addressId, int userId) {
    JSONObject resp = new JSONObject();
    
    try {
        // Ellenőrizzük, hogy a cím ehhez a userhez tartozik-e
        Addresses address = em.find(Addresses.class, addressId);
        if (address == null) {
            resp.put("status", "AddressNotFound");
            resp.put("statusCode", 404);
            resp.put("message", "A cím nem található");
            return resp;
        }
        
        // ⚠️ JAVÍTÁS: getUserId() egy Users objektumot ad vissza!
        if (address.getUserId().getId() != userId) {  // ← .getId() hozzáadva
            resp.put("status", "Unauthorized");
            resp.put("statusCode", 403);
            resp.put("message", "Nincs jogosultságod ehhez a címhez");
            return resp;
        }
        
        StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelAddresses");
        spq.registerStoredProcedureParameter("addressesIdIN", Integer.class, ParameterMode.IN);
        spq.setParameter("addressesIdIN", addressId);
        
        spq.execute();
        
        resp.put("status", "AddressDeleted");
        resp.put("statusCode", 200);
        resp.put("message", "Cím sikeresen törölve");
        
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
        resp.put("message", "Hiba történt a cím törlése során: " + e.getMessage());
    }
    
    return resp;
}

    
    public JSONObject setDefaultAddress(int addressId, int userId) {
    JSONObject resp = new JSONObject();
    
    try {
        // Ellenőrizzük, hogy a cím ehhez a userhez tartozik-e
        Addresses address = em.find(Addresses.class, addressId);
        if (address == null) {
            resp.put("status", "AddressNotFound");
            resp.put("statusCode", 404);
            resp.put("message", "A cím nem található");
            return resp;
        }
        
        // ⚠️ JAVÍTÁS: getUserId() egy Users objektumot ad vissza!
        if (address.getUserId().getId() != userId) {  // ← .getId() hozzáadva
            resp.put("status", "Unauthorized");
            resp.put("statusCode", 403);
            resp.put("message", "Nincs jogosultságod ehhez a címhez");
            return resp;
        }
        
        StoredProcedureQuery spq = em.createStoredProcedureQuery("setDefaultAddress");
        spq.registerStoredProcedureParameter("addressIdIN", Integer.class, ParameterMode.IN);
        spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
        
        spq.setParameter("addressIdIN", addressId);
        spq.setParameter("userIdIN", userId);
        
        spq.execute();
        
        resp.put("status", "DefaultAddressSet");
        resp.put("statusCode", 200);
        resp.put("message", "Alapértelmezett cím beállítva");
        
    } catch (Exception e) {
        e.printStackTrace();
        resp.put("status", "DatabaseError");
        resp.put("statusCode", 500);
        resp.put("message", "Hiba történt az alapértelmezett cím beállítása során: " + e.getMessage());
    }
    
    return resp;
}

    // ==================== ADMIN FUNKCIÓK ====================
    
    /**
     * Összes cím lekérdezése (admin funkció)
     * @return JSONObject az összes címmel
     */
    public JSONObject getAllAddresses() {
        JSONObject resp = new JSONObject();
        
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAllAddresses");
            
            List<Object[]> rows = spq.getResultList();
            JSONArray addresses = new JSONArray();
            
            for (Object[] row : rows) {
                JSONObject address = new JSONObject();
                address.put("id", row[0]);
                address.put("userId", row[1]);
                address.put("street", row[2]);
                address.put("city", row[3]);
                address.put("postalCode", row[4]);
                address.put("country", row[5]);
                address.put("isDefault", row[6]);
                address.put("createdAt", row[7]);
                
                addresses.put(address);
            }
            
            resp.put("addresses", addresses);
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", "Hiba történt a címek lekérdezése során: " + e.getMessage());
        }
        
        return resp;
    }

    /**
     * Egy konkrét cím lekérdezése ID alapján
     * @param addressId - Cím azonosítója
     * @return JSONObject a címmel
     */
    public JSONObject getAddressById(int addressId) {
        JSONObject resp = new JSONObject();
        
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAddressById");
            spq.registerStoredProcedureParameter("addressIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("addressIdIN", addressId);
            
            Object[] row = (Object[]) spq.getSingleResult();
            
            JSONObject address = new JSONObject();
            address.put("id", row[0]);
            address.put("userId", row[1]);
            address.put("street", row[2]);
            address.put("city", row[3]);
            address.put("postalCode", row[4]);
            address.put("country", row[5]);
            address.put("isDefault", row[6]);
            address.put("createdAt", row[7]);
            
            resp.put("address", address);
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            
        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "AddressNotFound");
            resp.put("statusCode", 404);
            resp.put("message", "A cím nem található");
        }
        
        return resp;
    }
}