import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { ProfileService } from '../services/profile.service';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-profilepage',
  standalone: true,
  imports: [HeaderComponent, FooterComponent, ReactiveFormsModule, CommonModule],
  templateUrl: './profilepage.component.html',
  styleUrl: './profilepage.component.css',
})
export class ProfilepageComponent implements OnInit {
  activeTab: string = 'fiokkezeles';
  
  customerDataForm!: FormGroup;
  passwordForm!: FormGroup;
  deliveryDataForm!: FormGroup;

  userData: any = null;
  
  isUpdatingProfile: boolean = false;
  isChangingPassword: boolean = false;

  showOldPassword: boolean = false;
  showNewPassword: boolean = false;
  showConfirmPassword: boolean = false;

  // Rendeléseim modal
  isOrdersModalOpen: boolean = false;
  
  // Kedvencek modal
  isFavoritesModalOpen: boolean = false;
  
  // Mock kedvencek
  mockFavorites = [
    {
      id: 1,
      name: 'Sony WH-1000XM5 Fejhallgató',
      category: 'Audió & Fejhallgatók',
      price: 159990,
      oldPrice: 189990,
      image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300&h=300&fit=crop',
      inStock: true
    },
    {
      id: 2,
      name: 'Apple MacBook Air M2',
      category: 'Laptopok',
      price: 549990,
      oldPrice: null,
      image: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=300&h=300&fit=crop',
      inStock: true
    },
    {
      id: 3,
      name: 'Samsung 4K Smart TV 55"',
      category: 'TV & Monitor',
      price: 289990,
      oldPrice: 349990,
      image: 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=300&h=300&fit=crop',
      inStock: false
    },
    {
      id: 4,
      name: 'Logitech MX Master 3S Egér',
      category: 'Perifériák',
      price: 44990,
      oldPrice: null,
      image: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=300&h=300&fit=crop',
      inStock: true
    },
    {
      id: 5,
      name: 'iPhone 15 Pro Max 256GB',
      category: 'Telefonok',
      price: 649990,
      oldPrice: 699990,
      image: 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=300&h=300&fit=crop',
      inStock: true
    },
    {
      id: 6,
      name: 'DJI Mini 3 Pro Drón',
      category: 'Drónok & Kamerák',
      price: 329990,
      oldPrice: null,
      image: 'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=300&h=300&fit=crop',
      inStock: false
    }
  ];
  
  // Mock rendelések
  mockOrders = [
    {
      id: 'ORD-2024-001',
      date: '2024.01.15.',
      status: 'Kiszállítva',
      statusClass: 'status-delivered',
      items: [
        { name: 'Wireless Bluetooth Fejhallgató', quantity: 1, price: 24990 },
        { name: 'USB-C Töltőkábel 2m', quantity: 2, price: 2990 }
      ],
      total: 30970
    },
    {
      id: 'ORD-2024-002',
      date: '2024.01.28.',
      status: 'Szállítás alatt',
      statusClass: 'status-shipping',
      items: [
        { name: 'Mechanikus Gaming Billentyűzet', quantity: 1, price: 45990 },
        { name: 'RGB Egérpad XL', quantity: 1, price: 8990 },
        { name: 'Gaming Egér 16000 DPI', quantity: 1, price: 19990 }
      ],
      total: 74970
    },
    {
      id: 'ORD-2024-003',
      date: '2024.02.02.',
      status: 'Feldolgozás alatt',
      statusClass: 'status-processing',
      items: [
        { name: 'Smart Watch Pro', quantity: 1, price: 89990 }
      ],
      total: 89990
    },
    {
      id: 'ORD-2023-047',
      date: '2023.12.20.',
      status: 'Kiszállítva',
      statusClass: 'status-delivered',
      items: [
        { name: 'Laptop Állvány Alumínium', quantity: 1, price: 12990 },
        { name: 'Webcam 1080p', quantity: 1, price: 15990 }
      ],
      total: 28980
    }
  ];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService,
    private profileService: ProfileService
  ) {}

  ngOnInit(): void {
    this.loadUserData();
  }

  loadUserData(): void {
    const currentUser = this.authService.getCurrentUser();
    
    if (currentUser) {
      const savedProfile = localStorage.getItem('currentUser');
      
      if (savedProfile) {
        this.userData = JSON.parse(savedProfile);
      } else {
        this.userData = {
          email: currentUser.email,
          username: currentUser.username,
          role: currentUser.role,
          telefonszam: '',
          vezetekNev: '',
          keresztNev: '',
          cim: { orszag: '', iranyitoszam: '', varos: '', utcaHazszam: '' }
        };
        localStorage.setItem('currentUser', JSON.stringify(this.userData));
      }
      
      this.initializeForms();
    } else {
      this.router.navigate(['/login']);
    }
  }

  initializeForms(): void {
    this.customerDataForm = this.fb.group({
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      vezetekNev: [this.userData?.vezetekNev || '', Validators.required],
      keresztNev: [this.userData?.keresztNev || '', Validators.required]
    });

    this.passwordForm = this.fb.group({
      regiJelszo: ['', Validators.required],
      ujJelszo: ['', [Validators.required, Validators.minLength(8)]],
      ujJelszoMegerosites: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });

    this.deliveryDataForm = this.fb.group({
      orszag: [this.userData?.cim?.orszag || '', Validators.required],
      iranyitoszam: [this.userData?.cim?.iranyitoszam || '', Validators.required],
      varos: [this.userData?.cim?.varos || '', Validators.required],
      utcaHazszam: [this.userData?.cim?.utcaHazszam || '', Validators.required],
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      telefonszam: [this.userData?.telefonszam || '', Validators.required]
    });
  }

  passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const newPassword = group.get('ujJelszo')?.value;
    const confirmPassword = group.get('ujJelszoMegerosites')?.value;
    return (newPassword !== confirmPassword) ? { passwordMismatch: true } : null;
  }

  togglePasswordVisibility(field: 'old' | 'new' | 'confirm'): void {
    if (field === 'old') this.showOldPassword = !this.showOldPassword;
    else if (field === 'new') this.showNewPassword = !this.showNewPassword;
    else this.showConfirmPassword = !this.showConfirmPassword;
  }

  getFullName(): string {
    return `${this.userData?.vezetekNev || ''} ${this.userData?.keresztNev || ''}`.trim() 
           || this.userData?.username || 'Felhasználó';
  }

  getFullAddress(): string {
    if (!this.userData?.cim) return '';
    const { varos, iranyitoszam, utcaHazszam } = this.userData.cim;
    return `${varos || ''}, ${iranyitoszam || ''}, ${utcaHazszam || ''}`.replace(/(^,\s*|,\s*$)/g, '');
  }

  hasDeliveryData(): boolean {
    if (!this.userData?.cim) return false;
    const { orszag, iranyitoszam, varos, utcaHazszam } = this.userData.cim;
    return !!(orszag || iranyitoszam || varos || utcaHazszam);
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  isAdmin(): boolean {
    return this.userData?.role === 'Admin';
  }

  onSubmit(): void {
    if (this.customerDataForm.valid && this.deliveryDataForm.valid) {
      const updatedData = {
        email: this.customerDataForm.value.email,
        vezetekNev: this.customerDataForm.value.vezetekNev,
        keresztNev: this.customerDataForm.value.keresztNev,
        telefonszam: this.deliveryDataForm.value.telefonszam,
        cim: {
          orszag: this.deliveryDataForm.value.orszag,
          iranyitoszam: this.deliveryDataForm.value.iranyitoszam,
          varos: this.deliveryDataForm.value.varos,
          utcaHazszam: this.deliveryDataForm.value.utcaHazszam
        }
      };

      this.isUpdatingProfile = true;

      this.profileService.updateUserProfile(updatedData).subscribe({
        next: (response) => {
          this.userData = { ...this.userData, ...updatedData };
          localStorage.setItem('currentUser', JSON.stringify(this.userData));
          alert('✅ Változások mentve!');
          this.isUpdatingProfile = false;
        },
        error: (error) => {
          this.isUpdatingProfile = false;
          this.userData = { ...this.userData, ...updatedData };
          localStorage.setItem('currentUser', JSON.stringify(this.userData));
          
          if (error.status === 401) {
            alert('❌ Érvénytelen token!');
            this.authService.logout();
            this.router.navigate(['/login']);
          } else {
            alert('⚠️ Adatok helyben mentve.');
          }
        }
      });
    } else {
      alert('⚠️ Töltsd ki az összes mezőt!');
    }
  }

  onPasswordChange(): void {
    if (!this.passwordForm.valid) {
      alert('⚠️ Töltsd ki az összes jelszó mezőt helyesen!');
      return;
    }

    const oldPassword = this.passwordForm.value.regiJelszo;
    const newPassword = this.passwordForm.value.ujJelszo;
    const confirmPassword = this.passwordForm.value.ujJelszoMegerosites;

    if (newPassword !== confirmPassword) {
      alert('❌ Az új jelszavak nem egyeznek!');
      return;
    }

    // Ellenőrizzük, hogy van-e token mielőtt hívnánk
    if (!this.authService.isLoggedIn()) {
      alert('❌ Lejárt a munkamenet, kérlek jelentkezz be újra!');
      this.authService.logout();
      this.router.navigate(['/login']);
      return;
    }

    this.isChangingPassword = true;

    this.authService.changePassword(oldPassword, newPassword).subscribe({
      next: (response) => {
        console.log('✅ SUCCESS! Backend response:', response);
        this.isChangingPassword = false;
        alert('✅ Jelszó sikeresen megváltoztatva!');
        this.passwordForm.reset();
        this.showOldPassword = false;
        this.showNewPassword = false;
        this.showConfirmPassword = false;
      },
      error: (error) => {
        console.log('❌ ERROR! Full error:', error);
        console.log('error.status:', error.status);
        console.log('error.error:', error.error);
        
        this.isChangingPassword = false;
        
        let errorMsg = '❌ Hiba történt!';
        
        if (error.status === 401) {
          const errorBody = error.error;
          const message = (errorBody?.message || '').toLowerCase();
          
          console.log('→ 401 error detected');
          console.log('→ errorBody.message:', errorBody?.message);
          console.log('→ errorBody.status:', errorBody?.status);
          
          // -----------------------------------------------------------
          // FONTOS: Megkülönböztetjük a két 401-es esetet a MESSAGE alapján!
          //
          // JWT filter válasza:       message = "Invalid token or request"
          // changePassword válasza:   message = "Old password is incorrect"
          // -----------------------------------------------------------
          
          if (message.includes('token') || message.includes('invalid token')) {
            // JWT filter dobta el → lejárt vagy érvénytelen token
            console.log('→ TOKEN HIBA - a kérés meg sem jutott a changePassword-höz');
            errorMsg = '❌ Lejárt a munkamenet, kérlek jelentkezz be újra!';
            this.authService.logout();
            this.router.navigate(['/login']);
          } 
          else if (message.includes('old password') || message.includes('incorrect')) {
            // A changePassword service válaszolt → a régi jelszó nem jó
            console.log('→ Backend says: Wrong old password');
            errorMsg = '❌ A régi jelszó helytelen!';
          } 
          else {
            // Ismeretlen 401 → biztonsági okokból kijelentkeztetjük
            console.log('→ Unknown 401, logging out for safety');
            errorMsg = '❌ Hitelesítési hiba! Kérlek jelentkezz be újra.';
            this.authService.logout();
            this.router.navigate(['/login']);
          }
        } else if (error.status === 400) {
          const errorBody = error.error;
          if (errorBody?.status === 'WeakPassword') {
            errorMsg = '❌ A jelszó legalább 8 karakter hosszú kell legyen!';
          } else {
            errorMsg = '❌ Érvénytelen kérés!';
          }
        } else if (error.status === 404) {
          errorMsg = '❌ Felhasználó nem található!';
        } else if (error.status === 500) {
          errorMsg = '❌ Szerver hiba!';
        } else if (error.status === 0) {
          errorMsg = '❌ Nincs kapcsolat a szerverrel!';
        }
        
        console.log('→ Final message:', errorMsg);
        alert(errorMsg);
      }
    });
  }

  resetChanges(): void {
    this.customerDataForm.patchValue({
      email: this.userData?.email || '',
      vezetekNev: this.userData?.vezetekNev || '',
      keresztNev: this.userData?.keresztNev || ''
    });

    this.passwordForm.reset();
    this.showOldPassword = false;
    this.showNewPassword = false;
    this.showConfirmPassword = false;

    this.deliveryDataForm.patchValue({
      orszag: this.userData?.cim?.orszag || '',
      iranyitoszam: this.userData?.cim?.iranyitoszam || '',
      varos: this.userData?.cim?.varos || '',
      utcaHazszam: this.userData?.cim?.utcaHazszam || '',
      email: this.userData?.email || '',
      telefonszam: this.userData?.telefonszam || ''
    });
    
    alert('Visszaállítva');
  }

  // Rendeléseim modal kezelés
  openOrdersModal(): void {
    this.isOrdersModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeOrdersModal(): void {
    this.isOrdersModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  // Kedvencek modal kezelés
  openFavoritesModal(): void {
    this.isFavoritesModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeFavoritesModal(): void {
    this.isFavoritesModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  removeFavorite(id: number): void {
    this.mockFavorites = this.mockFavorites.filter(item => item.id !== id);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/mainpage']);
  }
}