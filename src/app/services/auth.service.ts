import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { loginRequest, loginResponse, registerRequest, registerResponse } from '../model/auth.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';

  private http = inject(HttpClient);

  headers = {
    headers: new HttpHeaders({
      'Conent-Type': 'application/json',
      'Acces-Control-Allow-Origin': 'http://localhost:4200/'
    })
  }

  login(body: loginRequest): Observable<loginResponse> {
    return this.http.post<loginResponse>(`${this.apiUrl}/users/login`, body, this.headers);
  }

  register(body: registerRequest): Observable<registerResponse> {
    return this.http.post<registerResponse>(`${this.apiUrl}/users/register`, body, this.headers);
  }
}
