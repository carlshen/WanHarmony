import { ArticleEntity } from '../model/entity/ArticleEntity'
import { BannerEntity } from '../model/entity/BannerEntity'
import { NavData } from '../model/entity/NavData'
import { PageData } from '../model/entity/PageData'
import { TutorialEntity } from '../model/entity/TutorialEntity'
import { WanResponse } from '../model/entity/WanResponse'
import AxiosHttpRequest from './AxiosHttp'
import { AxiosError, AxiosRequestHeaders } from '@ohos/axios';
import { LogUtils } from '../utils/LogUtils';
import showToast from '../utils/ToastUtils';
import { hideLoadingDialog, showLoadingDialog } from '../utils/DialogUtils';
import { StorageUtils } from '../utils/StorageUtils';
import { StorageKeys } from '../utils/StorageKeys';
import { JsonUtils } from '../utils/JsonUtils';

export const UseAsync = true
let wanAndroidUrl = "https://www.wanandroid.com"

/**
 * axios请求客户端创建
 */
const axiosClient = new AxiosHttpRequest({
  baseURL: "https://www.wanandroid.com",
  timeout: 10 * 1000,
  checkResultCode: false,
  headers: {
    'Content-Type': 'application/json'
  } as AxiosRequestHeaders,
  interceptorHooks: {
    requestInterceptor: async (config) => {
      // 在发送请求之前做一些处理，例如打印请求信息
      LogUtils.debug('网络请求Request 请求方法:', `${config.method}`);
      LogUtils.debug('网络请求Request 请求链接:', `${config.url}`);
      // LogUtils.debug('网络请求Request Params:', `\n${JsonUtils.stringify(config.params)}`);
      // LogUtils.debug('网络请求Request Data:', `${JsonUtils.stringify(config.data)}`);
      axiosClient.config.showLoading = config.showLoading
      if (config.showLoading) {
        showLoadingDialog("加载中...")
      }
      if (config.checkLoginState) {
        let hasLogin = await StorageUtils.get(StorageKeys.USER_LOGIN, false)
        LogUtils.debug('网络请求Request 登录状态校验>>>', `${hasLogin.toString()}`);
        if (hasLogin) {
          return config
        } else {
          if (config.needJumpToLogin) {
            // Router.push(RoutePath.TestPage)
            // need jump to login page
            showLoadingDialog("请跳转到登录页面...")
          }
          throw new AxiosError("请登录")
        }
      }
      return config;
    },
    requestInterceptorCatch: (err) => {
      LogUtils.error("网络请求RequestError", err.toString())
      if (axiosClient.config.showLoading) {
        hideLoadingDialog()
      }
      return err;
    },
    responseInterceptor: (response) => {
      //优先执行自己的请求响应拦截器，在执行通用请求request的
      if (axiosClient.config.showLoading) {
        hideLoadingDialog()
      }
      // LogUtils.debug('网络请求响应Response:', `\n${JsonUtils.stringify(response.data)}`);
      if (response.status === 200) {
        // @ts-ignore
        const checkResultCode = response.config.checkResultCode
        if (checkResultCode && response.data.errorCode != 0) {
          showToast(response.data.errorMsg)
          return Promise.reject(response)
        }
        return Promise.resolve(response.data);
      } else {
        return Promise.reject(response);
      }
    },
    responseInterceptorCatch: (error) => {
      if (axiosClient.config.showLoading) {
        hideLoadingDialog()
      }
      LogUtils.error("网络请求响应异常", error.toString())
      errorHandler(error);
      return Promise.reject(error);
    },
  }
});

export function errorHandler(error: any) {
  if (error instanceof AxiosError) {
    showToast(error.message)
  } else if (error != undefined && error.response != undefined && error.response.status) {
    switch (error.response.status) {
    // 401: 未登录
    // 未登录则跳转登录页面，并携带当前页面的路径
    // 在登录成功后返回当前页面，这一步需要在登录页操作。
      case 401:

        break;
    // 403 token过期
    // 登录过期对用户进行提示
    // 清除本地token和清空vuex中token对象
    // 跳转登录页面
      case 403:
        showToast("登录过期，请重新登录")
      // 清除token
      // localStorage.removeItem('token');
        break;
    // 404请求不存在
      case 404:
        showToast("网络请求不存在")
        break;

    // 其他错误，直接抛出错误提示
      default:
        showToast(error.response.data.message)
    }

  }
}

export async function getBannerAsync(): Promise<BannerEntity[]> {
  try {
    let res = await axiosClient.get<WanResponse<BannerEntity[]>>(
      {
        url: wanAndroidUrl + "/banner/json",
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getBannerAsync success")
      return (res.data);
    } else {
      return new BannerEntity[0];
    }
  } catch (error) {
    LogUtils.error("getBannerAsync error")
    return error;
  }
}

export async function getArticleListAsync(pageNumber: number): Promise<ArticleEntity[]> {
  try {
    let res = await axiosClient.get<WanResponse<PageData<ArticleEntity>>>(
      {
        url: wanAndroidUrl + `/article/list/${pageNumber}/json`,
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getArticleListAsync success")
      return res.data.datas;
    } else {
      return new ArticleEntity[0];
    }
  } catch (error) {
    LogUtils.error("getArticleListAsync error")
    return error;
  }
}

export async function getTopArticleListAsync(): Promise<ArticleEntity[]> {
  try {
    let res = await axiosClient.get<WanResponse<ArticleEntity[]>>(
      {
        url: wanAndroidUrl + `/article/top/json`,
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getTopArticleListAsync success")
      return res.data.map((value) => {
        value.top = true
        return value
      });
    } else {
      return new ArticleEntity[0];
    }
  } catch (error) {
    LogUtils.error("getTopArticleListAsync error")
    return error;
  }
}

export async function getSquareArticleListAsync(pageNumber: number): Promise<ArticleEntity[]> {
  try {
    let res = await axiosClient.get<WanResponse<PageData<ArticleEntity>>>(
      {
        url: wanAndroidUrl + `/user_article/list/${pageNumber}/json`,
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getSquareArticleListAsync success")
      return res.data.datas;
    } else {
      return new ArticleEntity[0];
    }
  } catch (error) {
    LogUtils.error("getSquareArticleListAsync error")
    return error;
  }
}

export async function getNavigationDataAsync(): Promise<NavData[]> {
  try {
    let res = await axiosClient.get<WanResponse<NavData[]>>(
      {
        url: wanAndroidUrl + `/navi/json`,
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getNavigationDataAsync success")
      return res.data;
    } else {
      return new NavData[0];
    }
  } catch (error) {
    LogUtils.error("getNavigationDataAsync error")
    return error;
  }
}

export async function getTutorialDataAsync(): Promise<TutorialEntity[]> {
  try {
    let res = await axiosClient.get<WanResponse<TutorialEntity[]>>(
      {
        url: wanAndroidUrl + `/chapter/547/sublist/json`,
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getTutorialDataAsync success")
      return res.data;
    } else {
      return new TutorialEntity[0];
    }
  } catch (error) {
    LogUtils.error("getTutorialDataAsync error")
    return error;
  }
}

export async function getTutorialDetailDataAsync(tutorialId: number): Promise<ArticleEntity[]> {
  try {
    let res = await axiosClient.get<WanResponse<PageData<ArticleEntity>>>(
      {
        url: wanAndroidUrl + `/article/list/0/json?cid=${tutorialId}&order_type=1`,
        checkResultCode: true,
        showLoading: true
      }
    );
    if (res.errorCode == 0) {
      LogUtils.info("getTutorialDetailDataAsync success")
      return res.data.datas;
    } else {
      return new ArticleEntity[0];
    }
  } catch (error) {
    LogUtils.error("getTutorialDetailDataAsync error")
    return error;
  }
}

