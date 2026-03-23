import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface NewsletterResponse {
  status: string;
  statusCode: number;
  message: string;
  userId?: number;
}

export interface NewsletterType {
  type: string;
  name: string;
  description: string;
}

export interface NewsletterListResponse {
  status: string;
  statusCode: number;
  newsletters: NewsletterType[];
}

export interface Subscriber {
  id: number;
  username: string;
  email: string;
  subscribedAt: string;
}

export interface SubscribersResponse {
  status: string;
  statusCode: number;
  totalSubscribers: number;
  subscribers: Subscriber[];
}

export interface SendNewsletterResponse {
  status: string;
  statusCode: number;
  message: string;
  type?: string;
  totalSubscribers?: number;
  sentSuccessfully?: number;
  failed?: number;
}

@Injectable({
  providedIn: 'root'
})
export class NewsletterService {
  private apiUrl = 'http://localhost:8080/coreTech3-1.0-SNAPSHOT/api/newsletter';

  constructor(private http: HttpClient) {}

  /**
   * POST /newsletter/subscribe
   * Body: { email: string }
   * Feliratkozás hírlevélre - NEM kell JWT token
   */
  subscribe(email: string): Observable<NewsletterResponse> {
    return this.http.post<NewsletterResponse>(
      `${this.apiUrl}/subscribe`,
      { email }
    );
  }

  /**
   * POST /newsletter/send
   * Body: { type: string } - "new_arrivals" | "summer_sale" | "vip_exclusive"
   * Hírlevél küldése (admin funkció)
   */
  sendNewsletter(type: string): Observable<SendNewsletterResponse> {
    return this.http.post<SendNewsletterResponse>(
      `${this.apiUrl}/send`,
      { type },
      { headers: this.getAuthHeaders() }
    );
  }

  /**
   * GET /newsletter/all
   * Összes hírlevél típus lekérése
   */
  getAllNewsletterTypes(): Observable<NewsletterListResponse> {
    return this.http.get<NewsletterListResponse>(`${this.apiUrl}/all`);
  }

  /**
   * GET /newsletter/subscribers
   * Feliratkozottak listája (admin funkció)
   */
  getSubscribers(): Observable<SubscribersResponse> {
    return this.http.get<SubscribersResponse>(
      `${this.apiUrl}/subscribers`,
      { headers: this.getAuthHeaders() }
    );
  }

  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('JWT');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }
}