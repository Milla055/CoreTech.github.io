import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';

export interface User {
  id?: number;
  vezetekNev: string;
  keresztNev: string;
  email: string;
  role: string;
  cim?: {
    orszag: string;
    iranyitoszam: string;
    varos: string;
    utcaHazszam: string;
  };
  telefonszam?: string;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private apiUrl = 'http://localhost:4200'; // Replace with your API URL
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    // Load user from localStorage on service initialization
    const storedUser = localStorage.getItem('currentUser');
    if (storedUser) {
      this.currentUserSubject.next(JSON.parse(storedUser));
    }
  }

  /**
   * Get the currently logged-in user
   */
  getCurrentUser(): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/user/me`).pipe(
      tap(user => {
        this.currentUserSubject.next(user);
        localStorage.setItem('currentUser', JSON.stringify(user));
      })
    );
  }

  /**
   * Update user profile
   */
  updateUser(userData: Partial<User>): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/user/profile`, userData).pipe(
      tap(updatedUser => {
        this.currentUserSubject.next(updatedUser);
        localStorage.setItem('currentUser', JSON.stringify(updatedUser));
      })
    );
  }

  /**
   * Change user password
   */
  changePassword(oldPassword: string, newPassword: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/user/change-password`, {
      oldPassword,
      newPassword
    });
  }

  /**
   * Register a new user
   */
  register(userData: User & { password: string }): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/auth/register`, userData).pipe(
      tap(user => {
        this.currentUserSubject.next(user);
        localStorage.setItem('currentUser', JSON.stringify(user));
      })
    );
  }

  /**
   * Login user
   */
  login(email: string, password: string): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/auth/login`, { email, password }).pipe(
      tap(user => {
        this.currentUserSubject.next(user);
        localStorage.setItem('currentUser', JSON.stringify(user));
      })
    );
  }

  /**
   * Logout user
   */
  logout(): void {
    this.currentUserSubject.next(null);
    localStorage.removeItem('currentUser');
  }

  /**
   * Get current user value synchronously
   */
  getCurrentUserValue(): User | null {
    return this.currentUserSubject.value;
  }
}