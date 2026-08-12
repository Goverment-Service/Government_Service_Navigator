import React from 'react';

export default function Footer() {
  return (
    <footer style={{
      backgroundColor: '#161616',
      color: '#f4f4f4',
      padding: '2rem',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      borderTop: '2px solid #393939',
      marginTop: '3rem'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
        <div style={{ 
          display: 'flex', 
          height: '40px', 
          width: '40px', 
          alignItems: 'center', 
          justifyContent: 'center', 
          borderRadius: '50%', 
          border: '1px solid rgba(244,244,244,0.4)', 
          fontWeight: 'bold',
          fontSize: '13px' 
        }}>
          GSN
        </div>
        <div>
          <p style={{ fontWeight: 600, fontSize: '16px', margin: 0 }}>Government Service Navigator</p>
          <p style={{ fontSize: '12px', textTransform: 'uppercase', color: '#c6c6c6', margin: 0 }}>Registry Platform</p>
        </div>
      </div>
      <p style={{ margin: 0, fontSize: '14px', color: '#c6c6c6' }}>
        &copy; {new Date().getFullYear()} Government Service Navigator. All rights reserved.
      </p>
      <p style={{ margin: '0.5rem 0 0', fontSize: '12px', color: '#8d8d8d' }}>
        Authorized Government Personnel Only
      </p>
    </footer>
  );
}
