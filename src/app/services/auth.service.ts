import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
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
      this.currentUserSubject.next(JSON.parse(savedUser));
    }
  }

  login(body: loginRequest): Observable<loginResponse> {
    return this.http.post<loginResponse>(`${this.apiUrl}/Users/login`, body, this.headers).pipe(
      tap((result) => {
        // Store tokens
        localStorage.setItem('JWT', result.accessToken);
        localStorage.setItem('refreshToken', result.refreshToken);
        
        // Store user data from login response
        const userData = {
          username: result.username || body.email.split('@')[0], // Use username from response, or extract from email if not available
          email: body.email,
          role: result.role || 'User' // Store role from backend response
        };
        localStorage.setItem('user', JSON.stringify(userData));
        this.currentUserSubject.next(userData);
      })
    );
  }

  // Method to fetch user details from backend (including role)
  getUserDetails(): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    return this.http.get(`${this.apiUrl}/Users/current`, { headers }).pipe(
      tap((userData: any) => {
        // Update stored user data with backend info including role
        const updatedUser = {
          username: userData.username,
          email: userData.email,
          role: userData.role || 'User'
        };
        localStorage.setItem('user', JSON.stringify(updatedUser));
        this.currentUserSubject.next(updatedUser);
      })
    );
  }

  register(body: registerRequest): Observable<registerResponse> {
    return this.http.post<registerResponse>(`${this.apiUrl}/Users/createUser`, body, this.headers);
  }

  getUsername(): string | null {
    const user = localStorage.getItem('user');
    if (user) {
      return JSON.parse(user).username;
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

  // Method to change password
  changePassword(oldPassword: string, newPassword: string): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    const body = {
      oldPassword: oldPassword,
      newPassword: newPassword
    };

    // Adjust the endpoint URL according to your backend API
    return this.http.put(`${this.apiUrl}/Users/changePassword`, body, { headers });
  }

  logout() {
    localStorage.removeItem('JWT');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    localStorage.removeItem('currentUser');
    this.currentUserSubject.next(null);
  }
}