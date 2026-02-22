import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, tap, switchMap, throwError, catchError } from 'rxjs';
import { loginRequest, loginResponse, registerRequest, registerResponse } from '../model/auth.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';
  private http = inject(HttpClient);
  
  private currentUserSubject = new BehaviorSubject<any>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  headers = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json',
    })
  }

  constructor() {
    // Load user from localStorage on service init
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      const user = JSON.parse(savedUser);
      this.currentUserSubject.next(user);
      console.log('✅ User loaded from localStorage:', user);
    }
  }

  login(body: loginRequest): Observable<loginResponse> {
    return this.http.post<loginResponse>(`${this.apiUrl}/Users/login`, body, this.headers).pipe(
      tap((result) => {
        console.log('🔑 Login response:', result);
        
        // Store tokens
        localStorage.setItem('JWT', result.accessToken);
        localStorage.setItem('refreshToken', result.refreshToken);
        
        // Get userId - from response or JWT token
        let userId = result.userId;
        
        if (!userId) {
          // Fallback: decode JWT to get userId
          try {
            const tokenPayload = JSON.parse(atob(result.accessToken.split('.')[1]));
            userId = tokenPayload.userId;
            console.log('⚠️ userId not in response, extracted from JWT:', userId);
          } catch (e) {
            console.error('❌ Failed to decode JWT:', e);
          }
        }
        
        // Store user data with ID
        const userData = {
          id: userId,
          username: result.username,
          email: body.email,
          role: result.role || 'User'
        };
        
        console.log('✅ Storing user data with ID:', userData);
        localStorage.setItem('user', JSON.stringify(userData));
        localStorage.setItem('currentUser', JSON.stringify(userData));
        this.currentUserSubject.next(userData);
      })
    );
  }

  // Method to fetch user details from backend (backup if needed)
  getUserDetails(): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    return this.http.get(`${this.apiUrl}/admin/users/ID`, { headers }).pipe(
      tap((response: any) => {
        console.log('📥 Backend user details response:', response);
        
        // Extract user data from response
        const userData = response.user || response;
        
        // Update stored user data with backend info
        const updatedUser = {
          username: userData.username || userData.userName,
          email: userData.email,
          role: userData.role || 'User'
        };
        
        console.log('✅ Updating user data from getUserDetails:', updatedUser);
        localStorage.setItem('user', JSON.stringify(updatedUser));
        localStorage.setItem('currentUser', JSON.stringify(updatedUser));
        this.currentUserSubject.next(updatedUser);
      })
    );
  }

  register(body: registerRequest): Observable<registerResponse> {
    return this.http.post<registerResponse>(`${this.apiUrl}/Users/createUser`, body, this.headers).pipe(
      tap((response) => {
        console.log('🔑 Registration response:', response);
        // After registration, store the username
        if (response.username) {
          const userData = {
            username: response.username,  // ← Username from registration
            email: body.email,
            role: 'User' // Default role for new registrations
          };
          
          console.log('✅ Storing registered user data:', userData);
          localStorage.setItem('user', JSON.stringify(userData));
          localStorage.setItem('currentUser', JSON.stringify(userData));
          this.currentUserSubject.next(userData);
        }
      })
    );
  }

  getUsername(): string | null {
    const user = localStorage.getItem('user');
    if (user) {
      const parsed = JSON.parse(user);
      console.log('🏷️ Getting username:', parsed.username);
      return parsed.username;
    }
    return null;
  }

  getUserEmail(): string | null {
    const user = localStorage.getItem('user');
    if (user) {
      return JSON.parse(user).email;
    }
    return null;
  }

  getCurrentUser(): any {
    const user = localStorage.getItem('user');
    if (user) {
      return JSON.parse(user);
    }
    return null;
  }

  isLoggedIn(): boolean {
    return !!localStorage.getItem('JWT');
  }

  isAdmin(): boolean {
    const user = this.getCurrentUser();
    return user?.role === 'Admin';
  }

  /**
   * Helper: get auth headers with current valid token
   */
  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('JWT');
    console.log('🔐 Token for request:', token ? `${token.substring(0, 20)}...` : 'NULL!');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }

  /**
   * Refresh the access token using the refresh token
   */
  refreshAccessToken(): Observable<any> {
    const refreshToken = localStorage.getItem('refreshToken');
    
    if (!refreshToken) {
      return throwError(() => new Error('No refresh token available'));
    }

    return this.http.post<any>(`${this.apiUrl}/Users/refresh`, 
      { refreshToken: refreshToken },
      this.headers
    ).pipe(
      tap((result) => {
        console.log('🔄 Token refreshed successfully');
        if (result.accessToken) {
          localStorage.setItem('JWT', result.accessToken);
        }
        if (result.refreshToken) {
          localStorage.setItem('refreshToken', result.refreshToken);
        }
      })
    );
  }

  /**
   * Change password WITH old password verification (SECURE)
   * 
   * A user beírja a régi jelszót a formban → elküldjük plain text-ként →
   * a backend BCrypt.checkpw()-vel összehasonlítja a tárolt hash-sel.
   * A frontendnek NEM kell tudnia a hash-elt jelszót!
   */
  changePassword(oldPassword: string, newPassword: string): Observable<any> {
    const token = localStorage.getItem('JWT');

    // 1) Ellenőrizzük, hogy van-e token egyáltalán
    if (!token) {
      console.error('❌ No JWT token found in localStorage!');
      return throwError(() => ({ 
        status: 401, 
        error: { message: 'No token found - please log in again', status: 'TokenMissing' } 
      }));
    }

    console.log('🔐 changePassword - Token exists:', token.substring(0, 30) + '...');
    console.log('🔐 changePassword - Sending oldPassword (length):', oldPassword.length);
    console.log('🔐 changePassword - Sending newPassword (length):', newPassword.length);

    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    // 2) A body-ban "oldPassword" és "newPassword" kulcsokat küldünk
    //    hogy egyezzen a backend REST endpoint elvárt paramétereivel
    const body = {
      oldPassword: oldPassword,
      newPassword: newPassword
    };

    console.log('📤 changePassword request body keys:', Object.keys(body));

    return this.http.put(`${this.apiUrl}/Users/changePassword`, body, { headers }).pipe(
      catchError((error) => {
        // Ha 401-et kapunk "Invalid token" üzenettel, próbáljuk meg refreshelni
        if (error.status === 401 && error.error?.message?.toLowerCase().includes('token')) {
          console.log('🔄 Token expired, attempting refresh...');
          
          return this.refreshAccessToken().pipe(
            switchMap(() => {
              // Refresh sikeres, próbáljuk újra az eredeti kérést új tokennel
              const newToken = localStorage.getItem('JWT');
              const newHeaders = new HttpHeaders({
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${newToken}`
              });
              console.log('🔄 Retrying changePassword with new token...');
              return this.http.put(`${this.apiUrl}/Users/changePassword`, body, { headers: newHeaders });
            }),
            catchError((refreshError) => {
              // Refresh is elbukott — a user-t ki kell jelentkeztetni
              console.error('❌ Token refresh failed:', refreshError);
              return throwError(() => error); // Az eredeti hibát dobjuk vissza
            })
          );
        }
        
        // Ha nem token hiba, dobjuk tovább eredeti formában
        return throwError(() => error);
      })
    );
  }

  logout() {
    console.log('🚪 Logging out...');
    localStorage.removeItem('JWT');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    localStorage.removeItem('currentUser');
    this.currentUserSubject.next(null);
  }
}