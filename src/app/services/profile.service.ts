import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';

export interface UserProfile {
  id: number;
  username: string;
  teljesnev: string;
  email: string;
  phone: string;
  role: string;
  created_at: string;
  is_subscripted: boolean;
}

export interface Address {
  id: number;
  userId: number;  // Backend sends 'userId' not 'user_id'
  street: string;
  city: string;
  postalCode: string;  // Backend sends 'postalCode' not 'postal_code'
  country: string;
  isDefault: boolean;  // Backend sends 'isDefault' not 'is_default'
  createdAt?: string;  // Backend sends 'createdAt' not 'created_at'
}

interface ProfileResponse {
  status: string;
  statusCode: number;
  user?: UserProfile;
  message?: string;
}

interface AddressesResponse {
  status: string;
  statusCode: number;
  addresses?: Address[];
  message?: string;
}

interface AddressResponse {
  status: string;
  statusCode: number;
  address?: Address;
  message?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ProfileService {
  private http = inject(HttpClient);
  private baseUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';
  private usersUrl = `${this.baseUrl}/Users`;
  private addressUrl = `${this.baseUrl}/Addresses`;

  private getAuthHeaders() {
    const token = localStorage.getItem('JWT');
    return {
      headers: new HttpHeaders({
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      })
    };
  }

  // ==================== USER PROFILE ====================

  // Get user profile from backend (NOT IMPLEMENTED IN BACKEND YET - uses mock)
  getUserProfile(): Observable<UserProfile | null> {
    console.log('👤 Getting user profile from backend...');
    console.warn('⚠️ GET user profile endpoint NOT implemented in backend yet!');
    
    // TODO: When backend implements GET endpoint, use this:
    // return this.http.get<ProfileResponse>(`${this.usersUrl}/getUserProfile`, this.getAuthHeaders())
    
    // For now, return null to trigger mock data
    return of(null);
  }

  // Update user profile
  updateUserProfile(profileData: Partial<UserProfile>): Observable<boolean> {
    console.log('💾 Updating user profile:', profileData);
    
    // Backend expects: username, fullName, email, phone
    const payload = {
      username: profileData.username,
      fullName: profileData.teljesnev, // Backend expects 'fullName'
      email: profileData.email,
      phone: profileData.phone
    };
    
    return this.http.put<ProfileResponse>(
      `${this.usersUrl}/updateUserProfile`,
      payload,
      this.getAuthHeaders()
    ).pipe(
      tap(response => console.log('📦 Update response:', response)),
      map(response => {
        if (response.status === 'ProfileUpdated' || response.statusCode === 200) {
          console.log('✅ Profile updated successfully');
          return true;
        }
        console.error('❌ Profile update failed:', response.message);
        return false;
      }),
      catchError(err => {
        console.error('❌ Error updating profile:', err);
        return of(false);
      })
    );
  }

  // ==================== ADDRESSES ====================

  // Get all addresses for current user
  getAddresses(): Observable<Address[]> {
    console.log('🏠 Getting user addresses from backend...');
    
    return this.http.get<AddressesResponse>(
      `${this.addressUrl}/getUserAddresses`,
      this.getAuthHeaders()
    ).pipe(
      tap(response => console.log('📦 Addresses response:', response)),
      map(response => {
        if (response.status === 'Success' && response.addresses) {
          console.log('✅ Addresses loaded:', response.addresses.length, 'addresses');
          return response.addresses;
        }
        return [];
      }),
      catchError(err => {
        console.error('❌ Error loading addresses:', err);
        return of([]);
      })
    );
  }

  // Add new address
  addAddress(address: Omit<Address, 'id' | 'userId' | 'createdAt'>): Observable<boolean> {
    console.log('➕ Adding new address:', address);
    
    return this.http.post<AddressResponse>(
      `${this.addressUrl}/createAddress`,
      address,
      this.getAuthHeaders()
    ).pipe(
      tap(response => console.log('📦 Add address response:', response)),
      map(response => {
        if (response.status === 'AddressCreated' || response.statusCode === 201) {
          console.log('✅ Address added successfully');
          return true;
        }
        console.error('❌ Add address failed:', response.message);
        return false;
      }),
      catchError(err => {
        console.error('❌ Error adding address:', err);
        return of(false);
      })
    );
  }

  // Update existing address
  updateAddress(addressId: number, address: Partial<Address>): Observable<boolean> {
    console.log('✏️ Updating address:', addressId, address);
    
    return this.http.put<AddressResponse>(
      `${this.addressUrl}/updateAddress/${addressId}`,
      address,
      this.getAuthHeaders()
    ).pipe(
      tap(response => console.log('📦 Update address response:', response)),
      map(response => {
        if (response.status === 'AddressUpdated' || response.statusCode === 200) {
          console.log('✅ Address updated successfully');
          return true;
        }
        console.error('❌ Update address failed:', response.message);
        return false;
      }),
      catchError(err => {
        console.error('❌ Error updating address:', err);
        return of(false);
      })
    );
  }

  // Delete address
  deleteAddress(addressId: number): Observable<boolean> {
    console.log('🗑️ Deleting address:', addressId);
    
    return this.http.delete<AddressResponse>(
      `${this.addressUrl}/deleteAddress/${addressId}`,
      this.getAuthHeaders()
    ).pipe(
      tap(response => console.log('📦 Delete address response:', response)),
      map(response => {
        if (response.status === 'AddressDeleted' || response.statusCode === 200) {
          console.log('✅ Address deleted successfully');
          return true;
        }
        console.error('❌ Delete address failed:', response.message);
        return false;
      }),
      catchError(err => {
        console.error('❌ Error deleting address:', err);
        return of(false);
      })
    );
  }

  // Set default address
  setDefaultAddress(addressId: number): Observable<boolean> {
    console.log('⭐ Setting default address:', addressId);
    
    return this.http.put<AddressResponse>(
      `${this.addressUrl}/setDefaultAddress/${addressId}`,
      {},
      this.getAuthHeaders()
    ).pipe(
      tap(response => console.log('📦 Set default response:', response)),
      map(response => {
        if (response.status === 'DefaultAddressSet' || response.statusCode === 200) {
          console.log('✅ Default address set successfully');
          return true;
        }
        console.error('❌ Set default failed:', response.message);
        return false;
      }),
      catchError(err => {
        console.error('❌ Error setting default address:', err);
        return of(false);
      })
    );
  }
}