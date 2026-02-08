import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

export interface UserProfileData {
  vezetekNev?: string;
  keresztNev?: string;
  email?: string;
  telefonszam?: string;
  cim?: {
    orszag?: string;
    iranyitoszam?: string;
    varos?: string;
    utcaHazszam?: string;
  };
}

@Injectable({
  providedIn: 'root'
})
export class ProfileService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';
  private http = inject(HttpClient);

  /**
   * Update user profile data
   * Sends updated profile information to backend
   */
  updateUserProfile(profileData: UserProfileData): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    console.log('📤 Updating user profile:', profileData);

    // Adjust the endpoint based on your backend API
    return this.http.put(`${this.apiUrl}/Users/updateProfile`, profileData, { headers }).pipe(
      tap((response) => {
        console.log('✅ Profile updated successfully:', response);
        
        // Update localStorage with new data
        const currentUser = JSON.parse(localStorage.getItem('user') || '{}');
        const updatedUser = {
          ...currentUser,
          ...profileData,
          // Preserve username and role
          username: currentUser.username,
          role: currentUser.role
        };
        
        localStorage.setItem('user', JSON.stringify(updatedUser));
        localStorage.setItem('currentUser', JSON.stringify(updatedUser));
      })
    );
  }

  /**
   * Get current user's full profile data from backend
   */
  getUserProfile(): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    return this.http.get(`${this.apiUrl}/Users/profile`, { headers }).pipe(
      tap((response: any) => {
        console.log('📥 User profile loaded:', response);
      })
    );
  }
}