import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, tap, switchMap } from 'rxjs';
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
      }),
      switchMap((result) => {
        // Fetch user profile to get username
        return this.getUserProfile().pipe(
          tap((profile: any) => {
            const userData = {
              username: profile.username,
              email: profile.email || body.email
            };
            localStorage.setItem('user', JSON.stringify(userData));
            this.currentUserSubject.next(userData);
          }),
          // Return the original login result
          tap(() => result)
        );
      })
    );
  }

  // Add this method to fetch user profile
  getUserProfile(): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
    return this.http.get(`${this.apiUrl}/Users/login`, { headers }); // adjust endpoint
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

  isLoggedIn(): boolean {
    return !!localStorage.getItem('JWT');
  }

  logout() {
    localStorage.removeItem('JWT');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    this.currentUserSubject.next(null);
  }
}