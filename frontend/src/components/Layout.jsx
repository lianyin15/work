import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login');
  }

  return (
    <div>
      <nav className="navbar">
        <div className="navbar-inner">
          <NavLink to="/" className="navbar-brand">打卡激励</NavLink>
          <div className="navbar-links">
            <NavLink to="/" end>任务列表</NavLink>
            <NavLink to="/tasks/create">创建任务</NavLink>
            <NavLink to="/leaderboard">排行榜</NavLink>
            <NavLink to="/profile">个人中心</NavLink>
          </div>
          <div className="navbar-right">
            <span className="navbar-user">{user?.nickname} ({user?.points}分)</span>
            <button className="navbar-logout" onClick={handleLogout}>退出</button>
          </div>
        </div>
      </nav>
      <div className="page">
        <Outlet />
      </div>
    </div>
  );
}
